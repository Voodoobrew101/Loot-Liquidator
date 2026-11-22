"""Import public Wago DB2 CSV exports for one pinned build, then compile the UI catalog.

Usage: python tools/import_profession_catalog.py --csv-dir PATH
       python tools/import_profession_catalog.py  # regenerate from reviewed JSON
No yield formulas or rating curves are derived from these UI tables.
"""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
BUILD = '12.1.5.70783'
SNAPSHOT = ROOT / 'database/wago-professions-70783.json'
TABLES = ['SkillLine', 'SkillLineXTraitTree', 'TraitTree', 'TraitNode',
          'TraitNodeXTraitNodeEntry', 'TraitNodeEntry', 'TraitDefinition', 'SpellName',
          'ProfTraitPathNode', 'TraitEdge']


def extract(folder):
    sources = []
    def read(table):
        path = folder / f'{table}.{BUILD}.csv'
        sources.append({'table': table, 'url': f'https://wago.tools/db2/{table}?build={BUILD}',
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
        with path.open(encoding='utf-8-sig', newline='') as stream:
            rows = list(csv.DictReader(stream))
        return {int(row['ID']): row for row in rows}
    tables = {name: read(name) for name in TABLES}
    skills, trees, nodes = (tables[t] for t in ['SkillLine', 'TraitTree', 'TraitNode'])
    paths = {int(r['TraitNodeID']) for r in tables['ProfTraitPathNode'].values()}
    entries = tables['TraitNodeEntry']
    spend = {}
    for r in tables['TraitNodeXTraitNodeEntry'].values():
        if int(r['TraitNodeID']) not in paths:
            continue
        entry = entries[int(r['TraitNodeEntryID'])]
        if int(entry['NodeEntryType']) == 7:
            node = int(r['TraitNodeID'])
            if node in spend and spend[node] != entry:
                old = spend[node]
                a, b = [tables['TraitDefinition'][int(e['TraitDefinitionID'])] for e in (old, entry)]
                assert old['MaxRanks'] == entry['MaxRanks'] and a['OverrideName_lang'] == b['OverrideName_lang'], f'ambiguous path {node}'
            spend[node] = entry
    parents = {}
    for r in tables['TraitEdge'].values():
        parent, child = int(r['LeftTraitNodeID']), int(r['RightTraitNodeID'])
        if parent in paths and child in paths:
            assert child not in parents or parents[child] == parent
            parents[child] = parent
    catalogs = {}
    for link in tables['SkillLineXTraitTree'].values():
        line = int(link['SkillLineID'])
        skill = skills[line]
        expansion = next((v for k, v in [('Dragon Isles', 9), ('Khaz Algar', 10), ('Midnight', 11)]
                          if skill['DisplayName_lang'].startswith(k + ' ')), None)
        if expansion is None:
            continue
        profession = skills[int(skill['ParentSkillLineID'])]['DisplayName_lang']
        key = f'{profession}:{expansion}'
        catalog = catalogs.setdefault(key, {'lineID': line, 'nodes': []})
        tree_id = int(link['TraitTreeID'])
        root_id = int(trees[tree_id]['FirstTraitNodeID'])
        def description(node_id):
            entry = spend[node_id]
            definition = tables['TraitDefinition'][int(entry['TraitDefinitionID'])]
            spell = int(definition['SpellID'])
            name = definition['OverrideName_lang'] or tables['SpellName'].get(spell, {}).get('Name_lang')
            assert name, f'missing name {node_id}'
            return name, definition, entry
        root_name, _, _ = description(root_id)
        tree_nodes = [n for n in paths if int(nodes[n]['TraitTreeID']) == tree_id]
        for node_id in sorted(tree_nodes):
            name, definition, entry = description(node_id)
            depth, ancestor, seen = 0, node_id, set()
            while ancestor in parents:
                assert ancestor not in seen, f'cycle {node_id}'
                seen.add(ancestor)
                depth += 1
                ancestor = parents[ancestor]
            if ancestor != root_id:
                continue  # Retired/unreachable paths are not part of this tree.
            row = {'id': node_id, 'name': name, 'tab': root_name, 'treeID': tree_id,
                   'maxRank': int(entry['MaxRanks']), 'definitionID': int(definition['ID']),
                   'depth': depth, 'requirementsKnown': False}
            if node_id in parents:
                row['parentID'] = parents[node_id]
            if definition['OverrideDescription_lang'] and '$' not in definition['OverrideDescription_lang']:
                row['description'] = definition['OverrideDescription_lang']
            catalog['nodes'].append(row)
    assert len(catalogs) == 33, f'expected 11 professions in each modern expansion: {len(catalogs)}'
    for catalog in catalogs.values():
        ids = [n['id'] for n in catalog['nodes']]
        assert len(ids) == len(set(ids)) and ids
    return {'build': BUILD, 'locale': 'enUS', 'sources': sources, 'catalogs': catalogs}


def lua(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'


def processing_control_nodes(document, source):
    """Use the runtime's control policy; never prune shared valuation effects."""
    from profession_profile_rules import lua as profile_lua
    spells = {row['spellID']: row for row in source['recipeRouting']['spells']}
    operations = {}
    for identity, recipe in document['recipes'].items():
        spell = spells.get(identity, {})
        name = spell.get('name', '').lower()
        method = None
        if any(effect['Effect'] == 99 for effect in spell.get('effects', [])):
            method = 'Disenchant'
        elif recipe.get('salvage'):
            if recipe['profession'] == 'Inscription' and name.endswith('milling'):
                method = 'Mill'
            elif recipe['profession'] == 'Jewelcrafting' and name.endswith('prospecting'):
                method = 'Prospect'
            elif recipe['profession'] == 'Engineering':
                method = 'Recycle'
        elif recipe.get('outputIDs'):
            method = 'Smelt' if recipe['profession'] == 'Mining' and name.startswith('smelt ') else 'Craft'
        if method is None:
            continue
        expansions = [recipe['expansionID']] if recipe['expansionID'] in (9, 10, 11) else (
            [9, 10, 11] if method in {'Disenchant', 'Smelt'} else [])
        for expansion in expansions:
            key = f"{recipe['profession']}:{expansion}"
            operations.setdefault(key, []).append({'method': method, 'recipeID': identity,
                'labels': recipe['labels'], 'supportsResourcefulness': recipe.get('supportsResourcefulness'),
                'supportsMulticraft': recipe.get('supportsMulticraft'), 'outputCount': recipe.get('outputCount')})
    # Only the small profile/operation view crosses the Lua boundary. Native
    # items, families and the complete recipe table never enter this UI pass.
    view = {key: document[key] for key in ('profiles', 'build', 'clientVersion')}
    script = "local LL={ItemDB={professionProfiles=" + profile_lua(view) + "}}\n"
    script += "local operations=" + profile_lua(operations) + "\n"
    script += "GetBuildInfo=function()local d=LL.ItemDB.professionProfiles;return d.clientVersion,tostring(d.build)end\n"
    script += "assert(loadfile(" + profile_lua((ROOT / 'LootLiquidator/ProfessionModels.lua').as_posix()) + "))('LootLiquidator',LL)\n"
    script += r'''
for key,profile in pairs(LL.ItemDB.professionProfiles.profiles)do
 local methods=LL:ProfessionTooltipMethods(profile.profession)
 if methods then
  print(key..string.char(9))
  local keep={}
  for id,node in pairs(profile.nodes)do
   local function consider(effects)
    for _,effect in ipairs(effects or{})do
     if LL:ProfessionEffectSupportsTooltipControl(effect,profile.profession,profile.expansionID,
       methods,operations[key]or{})then keep[id]=true;return end
    end
   end
   consider(node.pointEffects);consider(node.learningEffects)
   for _,milestone in ipairs(node.milestones or{})do consider(milestone.effects)end
  end
  local pending={};for id in pairs(keep)do pending[#pending+1]=id end
  while #pending>0 do
   local id=table.remove(pending);local parent=profile.nodes[id].parentID
   if profile.nodes[parent]and not keep[parent]then keep[parent]=true;pending[#pending+1]=parent end
  end
  for id in pairs(keep)do print(key..string.char(9)..id)end
 end
end
'''
    executable = shutil.which(os.environ.get('LUA51', 'lua5.1')) or shutil.which('lua')
    if executable:
        lines = subprocess.run([executable, '-'], input=script, text=True, encoding='utf-8',
                               capture_output=True, cwd=ROOT, check=True).stdout.splitlines()
    else:
        # The Windows build workspace already provides its Lua5.1 runner here;
        # ordinary builds use the same Lua executable as compile_itemdb.lua.
        local_runner = ROOT.parent / '.tools/python313'
        if local_runner.is_dir():
            sys.path.insert(0, str(local_runner))
        from lupa.lua51 import LuaRuntime
        lines = []
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.globals().print = lambda row: lines.append(row)
        runtime.execute(script)
    result = {}
    for line in lines:
        key, identity = line.split('\t', 1)
        nodes = result.setdefault(key, set())
        if identity:
            nodes.add(int(identity))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--csv-dir', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.csv_dir:
        data = extract(args.csv_dir)
        SNAPSHOT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    data = json.loads(SNAPSHOT.read_text(encoding='utf-8'))
    target = ROOT / 'LootLiquidator/ProfessionCatalog.lua'
    lines = ['-- Generated by tools/import_profession_catalog.py; public Wago UI data only.',
             '-- No profession access, unlock validation or yield coefficients are granted.',
             'local _, LL = ...', 'LL.ProfessionCatalogBuild=' + lua(data['build']),
             'LL.ProfessionCatalog={']
    from profession_profile_rules import build, load_source
    source = load_source()
    control_nodes = processing_control_nodes(build(source)[0], source)
    retained_catalogs = {}
    for key, original in sorted(data['catalogs'].items()):
        if key not in control_nodes:
            continue
        catalog = dict(original)
        retained = control_nodes[key]
        catalog['nodes'] = [node for node in original['nodes'] if node['id'] in retained]
        retained_catalogs[key] = catalog
        lines.append('[' + lua(key) + ']=' + lua(catalog) + ',')
    lines.append('}')
    output = '\n'.join(lines) + '\n'
    if args.check:
        assert target.read_text(encoding='utf-8') == output, 'Regenerate the profession catalog'
    else:
        target.write_text(output, encoding='utf-8', newline='\n')
    print(f"PASS: {len(retained_catalogs)} processing catalogs, {sum(len(c['nodes']) for c in retained_catalogs.values())} paths; {data['build']}")


if __name__ == '__main__':
    main()
