#!/usr/bin/env python3
"""Stable keys for source URLs, shared by the estimator and the migration inventory."""
import re


def normalize_url(url):
    """Stable key for a source URL so copies of one link compare equal.
    Keeps what distinguishes a source (Reddit post ID, Wowhead entity + comment ID, forum
    thread ID); drops slugs, query strings, tracking and trailing punctuation."""
    u = url.strip().rstrip(".,;:'\"*)")
    u = re.sub(r"^https?://", "", u, flags=re.I)
    host, _, rest = u.partition("/")
    host = host.lower()
    for pre in ("www.", "old.", "new.", "np."):
        if host.startswith(pre):
            host = host[len(pre):]
    frag = ""
    if "#" in rest:
        rest, frag = rest.split("#", 1)
    rest = rest.split("?", 1)[0].rstrip("/")
    if host.endswith("reddit.com") or host == "redd.it":
        m = re.search(r"comments/([a-z0-9]+)(?:/[^/]*/([a-z0-9]+))?", rest, re.I)
        if m:
            return "reddit:" + m.group(1).lower() + (":" + m.group(2).lower() if m.group(2) else "")
        return "reddit:/" + rest.lower()
    if host.endswith("wowhead.com"):
        sub = host[: -len("wowhead.com")].rstrip(".")
        m = re.search(r"^(?:([\w-]+)/)?(item|spell|npc|object|quest|guide|news|guides)[=/]([\w-]+)", rest)
        key = f"wowhead:{m.group(2)}={m.group(3)}" if m else "wowhead:/" + rest.lower()
        if m and m.group(1):  # game flavour path such as wotlk/, classic/, ptr/
            key += "@" + m.group(1).lower()
        if sub and sub not in ("www",):
            key += "@" + sub
        c = re.search(r"comments:id=(\d+)", frag)
        if c:
            key += "#c" + c.group(1)
        return key
    if "forums.blizzard.com" in host:
        m = re.search(r"/t/(?:[^/]+/)?(\d+)(?:/(\d+))?", "/" + rest)
        if m:
            return "blizzforum:" + m.group(1) + (":" + m.group(2) if m.group(2) else "")
    if host == "docs.google.com":
        m = re.search(r"/d/([\w-]+)", rest)
        if m:
            return "gdoc:" + m.group(1)
    return host + "/" + rest.lower()
