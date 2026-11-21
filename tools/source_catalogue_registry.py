"""Discover pinned research catalogues without asserting scientific approval.

Returned paths are relative to the snapshot root. A registry is authoritative;
its absence alone permits the original default catalogue for older snapshots.
This module never fetches, updates, writes, commits, or approves research data.
"""
import json
from pathlib import Path, PurePosixPath

REGISTRY = Path('research/v3/evidence/master/source-catalogues.json')
EVIDENCE = Path('research/v3/evidence')
DEFAULT_CATALOGUE = EVIDENCE / 'master/backlog-catalogue-20261120'


def _catalogue_path(snapshot, value):
    if not isinstance(value,str) or not value or '\\' in value or ':' in value:
        raise ValueError('Catalogue path must be a canonical relative POSIX path')
    path=PurePosixPath(value)
    if path.is_absolute() or value!=path.as_posix() or any(part in {'.','..'} for part in path.parts):
        raise ValueError('Catalogue path must not contain absolute paths or traversal aliases')
    relative=Path(*path.parts)
    if not relative.is_relative_to(EVIDENCE) or relative==EVIDENCE:
        raise ValueError('Catalogue path must be inside research/v3/evidence')
    root=Path(snapshot).resolve()
    evidence=(root/EVIDENCE).resolve()
    target=(root/relative).resolve()
    if not evidence.is_relative_to(root) or not target.is_relative_to(evidence):
        raise ValueError('Catalogue path escapes the pinned research evidence through a symlink')
    return relative,target


def _manifest_within_evidence(snapshot, target):
    manifest=target/'manifest.json'
    if not manifest.is_file():
        raise ValueError('Enabled catalogue requires manifest.json: '+str(target))
    if not manifest.resolve().is_relative_to((Path(snapshot).resolve()/EVIDENCE).resolve()):
        raise ValueError('Catalogue manifest escapes the pinned research evidence')


def catalogue_paths(snapshot):
    """Return enabled catalogue folders; registry order is retained exactly.

    For snapshots preceding the registry, a default manifest or an existing
    standalone admitted-models file retains its previous consumer behavior.
    Neither discovery path supplies scientific approval or bypasses validation.
    """
    root=Path(snapshot).resolve();registry=root/REGISTRY
    if not registry.exists():
        relative,target=_catalogue_path(root,DEFAULT_CATALOGUE.as_posix())
        if (target/'manifest.json').is_file() or (target/'admitted-models.json').is_file():
            for name in ('manifest.json','admitted-models.json'):
                file=target/name
                if file.exists() and not file.resolve().is_relative_to((root/EVIDENCE).resolve()):
                    raise ValueError('Legacy catalogue file escapes the pinned research evidence')
            return [relative]
        return []
    if not registry.is_file() or not registry.resolve().is_relative_to((root/EVIDENCE).resolve()):
        raise ValueError('Source catalogue registry escapes the pinned research evidence')
    document=json.loads(registry.read_text(encoding='utf-8-sig'))
    if (not isinstance(document,dict) or type(document.get('schemaVersion')) is not int
            or document['schemaVersion']!=1 or not isinstance(document.get('catalogues'),list)):
        raise ValueError('Unsupported source catalogue registry schema')
    result=[];identities=set();paths=set();resolved_paths=set()
    for entry in document['catalogues']:
        if not isinstance(entry,dict):raise ValueError('Catalogue registry entry must be an object')
        identity=entry.get('catalogueID')
        if not isinstance(identity,str) or not identity.strip() or identity!=identity.strip():
            raise ValueError('Catalogue registry identity is missing or ambiguous')
        if identity in identities:raise ValueError('Duplicate catalogue registry identity: '+identity)
        if type(entry.get('enabled')) is not bool:raise ValueError('Catalogue enabled state must be explicit boolean')
        relative,target=_catalogue_path(root,entry.get('path'))
        canonical=relative.as_posix()
        if canonical in paths or target in resolved_paths:raise ValueError('Duplicate catalogue registry path: '+canonical)
        identities.add(identity);paths.add(canonical);resolved_paths.add(target)
        if entry['enabled']:
            _manifest_within_evidence(root,target)
            result.append(relative)
    return result
