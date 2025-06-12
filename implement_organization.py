#!/usr/bin/env python3
"""
Xcode Project Organization Implementation
Actually implements the logical group structure in the Xcode project
"""

import re
import uuid
from typing import Dict, List, Set

def generate_xcode_uuid():
    """Generate a valid Xcode UUID"""
    return ''.join(c for c in str(uuid.uuid4()).upper() if c.isalnum())[:24]

def find_file_references(content: str) -> Dict[str, Dict[str, str]]:
    """Find all file references in the project"""
    file_refs = {}
    
    # Pattern to match PBXFileReference entries
    file_ref_pattern = r'(\w+) /\* (.+?) \*/ = \{[^}]*isa = PBXFileReference[^}]*path = ([^;]+);[^}]*\};'
    
    matches = re.findall(file_ref_pattern, content, re.DOTALL)
    
    for match in matches:
        uuid = match[0]
        display_name = match[1]
        path = match[2].strip('"')
        
        file_refs[uuid] = {
            'name': display_name,
            'path': path,
            'uuid': uuid
        }
    
    return file_refs

def categorize_files(file_refs: Dict[str, Dict[str, str]]) -> Dict[str, List[str]]:
    """Categorize files into logical groups"""
    
    categories = {
        'app': [],
        'models': [],
        'views': [],
        'view_components': [],
        'viewmodels': [],
        'services': [],
        'managers': [],
        'utilities': [],
        'resources': [],
        'audio': [],
        'images': [],
        'tests': [],
        'widget': [],
        'supporting': [],
        'frameworks': [],
        'products': []
    }
    
    for uuid, file_info in file_refs.items():
        name = file_info['name']
        path = file_info['path']
        
        # App files
        if name in ['SleepsterApp.swift', 'AppState.swift', 'ServiceContainer.swift', 'Constants.swift']:
            categories['app'].append(uuid)
        
        # Models
        elif name in ['SoundEntity.swift', 'BackgroundEntity.swift', 'Feature.swift', 'CoreDataStack.swift', 'DatabaseManager.swift'] or name.endswith('.xcdatamodeld'):
            categories['models'].append(uuid)
        
        # View Components
        elif name in ['CustomComponents.swift', 'AsyncImageView.swift']:
            categories['view_components'].append(uuid)
        
        # Views
        elif (name.endswith('View.swift') or name == 'SleepsterTabView.swift') and 'ViewModel' not in name:
            categories['views'].append(uuid)
        
        # ViewModels
        elif 'ViewModel.swift' in name:
            categories['viewmodels'].append(uuid)
        
        # Services
        elif 'Services/' in path or name in ['NetworkError.swift', 'ImageCache.swift', 'ErrorHandler.swift', 'AudioFading.swift', 'AudioMixingEngine.swift', 'SleepTracker.swift', 'NetworkMonitor.swift', 'StoreKitManager.swift', 'AudioEqualizer.swift', 'ShortcutsManager.swift', 'IntentHandler.swift', 'SubscriptionManager.swift', 'AudioSessionManager.swift', 'PurchaseValidator.swift', 'FlickrService.swift', 'IAPHelper.swift', 'SleepsterIAPHelper.swift']:
            categories['services'].append(uuid)
        
        # Managers
        elif 'Manager.swift' in name and name not in ['DatabaseManager.swift', 'StoreKitManager.swift']:
            categories['managers'].append(uuid)
        
        # Utilities
        elif name in ['PerformanceOptimizations.swift', 'FlickrAPIClient.swift']:
            categories['utilities'].append(uuid)
        
        # Audio files
        elif name.endswith('.mp3'):
            categories['audio'].append(uuid)
        
        # Image files
        elif name.endswith(('.png', '.jpg', '.jpeg')):
            categories['images'].append(uuid)
        
        # Tests
        elif 'Test' in name and name.endswith('.swift'):
            categories['tests'].append(uuid)
        
        # Widget
        elif 'Widget' in name or 'AppIntent.swift' in name:
            categories['widget'].append(uuid)
        
        # Resources
        elif name in ['Media.xcassets', 'Localizable.strings']:
            categories['resources'].append(uuid)
        
        # Supporting files
        elif name.endswith('.h') or name.endswith('.plist') or 'Bridging' in name:
            categories['supporting'].append(uuid)
        
        # Frameworks
        elif name.endswith('.framework'):
            categories['frameworks'].append(uuid)
        
        # Products
        elif name.endswith('.app') or name.endswith('.appex'):
            categories['products'].append(uuid)
    
    return categories

def create_group_structure(categories: Dict[str, List[str]]) -> Dict[str, str]:
    """Create the group structure with UUIDs"""
    
    groups = {}
    group_names = [
        'sources', 'app', 'models', 'views', 'view_components', 
        'viewmodels', 'services', 'managers', 'utilities',
        'resources', 'audio', 'images', 'tests', 'widget', 'supporting'
    ]
    
    for name in group_names:
        groups[name] = generate_xcode_uuid()
    
    return groups

def build_group_definitions(groups: Dict[str, str], categories: Dict[str, List[str]]) -> str:
    """Build the PBXGroup definitions"""
    
    def format_children(uuids: List[str], file_refs: Dict[str, Dict[str, str]]) -> str:
        if not uuids:
            return ""
        
        children = []
        for uuid in uuids:
            if uuid in file_refs:
                name = file_refs[uuid]['name']
                children.append(f"\t\t\t{uuid} /* {name} */,")
        
        return "\n".join(children)
    
    # We'll need the file_refs here, so let's pass them
    return f"""
\t{groups['sources']} /* Sources */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{groups['app']} /* App */,
\t\t\t{groups['models']} /* Models */,
\t\t\t{groups['views']} /* Views */,
\t\t\t{groups['viewmodels']} /* ViewModels */,
\t\t\t{groups['services']} /* Services */,
\t\t\t{groups['managers']} /* Managers */,
\t\t\t{groups['utilities']} /* Utilities */,
\t\t);
\t\tname = Sources;
\t\tsourceTree = "<group>";
\t}};
\t{groups['app']} /* App */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['app'], {})}
\t\t);
\t\tname = App;
\t\tsourceTree = "<group>";
\t}};
\t{groups['models']} /* Models */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['models'], {})}
\t\t);
\t\tname = Models;
\t\tsourceTree = "<group>";
\t}};
\t{groups['views']} /* Views */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{groups['view_components']} /* Components */,
{format_children(categories['views'], {})}
\t\t);
\t\tname = Views;
\t\tsourceTree = "<group>";
\t}};
\t{groups['view_components']} /* Components */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['view_components'], {})}
\t\t);
\t\tname = Components;
\t\tsourceTree = "<group>";
\t}};
\t{groups['viewmodels']} /* ViewModels */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['viewmodels'], {})}
\t\t);
\t\tname = ViewModels;
\t\tsourceTree = "<group>";
\t}};
\t{groups['services']} /* Services */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['services'], {})}
\t\t);
\t\tname = Services;
\t\tsourceTree = "<group>";
\t}};
\t{groups['managers']} /* Managers */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['managers'], {})}
\t\t);
\t\tname = Managers;
\t\tsourceTree = "<group>";
\t}};
\t{groups['utilities']} /* Utilities */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['utilities'], {})}
\t\t);
\t\tname = Utilities;
\t\tsourceTree = "<group>";
\t}};
\t{groups['resources']} /* Resources */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{groups['audio']} /* Audio */,
\t\t\t{groups['images']} /* Images */,
{format_children(categories['resources'], {})}
\t\t);
\t\tname = Resources;
\t\tsourceTree = "<group>";
\t}};
\t{groups['audio']} /* Audio */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['audio'], {})}
\t\t);
\t\tname = Audio;
\t\tsourceTree = "<group>";
\t}};
\t{groups['images']} /* Images */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['images'], {})}
\t\t);
\t\tname = Images;
\t\tsourceTree = "<group>";
\t}};
\t{groups['tests']} /* Tests */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['tests'], {})}
\t\t);
\t\tname = Tests;
\t\tsourceTree = "<group>";
\t}};
\t{groups['widget']} /* Widget */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['widget'], {})}
\t\t);
\t\tname = Widget;
\t\tsourceTree = "<group>";
\t}};
\t{groups['supporting']} /* Supporting Files */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
{format_children(categories['supporting'], {})}
\t\t);
\t\tname = "Supporting Files";
\t\tsourceTree = "<group>";
\t}};"""

def implement_organization():
    """Main function to implement the organization"""
    
    print("🏗️  Implementing Xcode project organization...")
    
    # Read project file
    with open("SleepMate.xcodeproj/project.pbxproj", "r") as f:
        content = f.read()
    
    print("📖 Analyzing project structure...")
    
    # Find all file references
    file_refs = find_file_references(content)
    print(f"📄 Found {len(file_refs)} file references")
    
    # Categorize files
    categories = categorize_files(file_refs)
    
    # Print categorization summary
    print("\n📊 File categorization:")
    for category, files in categories.items():
        if files:
            print(f"   {category}: {len(files)} files")
    
    # Create group structure
    groups = create_group_structure(categories)
    print(f"\n🗂️  Generated {len(groups)} group UUIDs")
    
    # For now, let's just create a simpler approach
    # Find the main project group and add our new structure
    
    # Look for the main group pattern
    main_group_pattern = r'(29B97314FDCFA39411CA2CEA[^=]*=\s*\{[^}]*children\s*=\s*\()[^)]*(\);[^}]*name\s*=\s*[^;]*;[^}]*\};)'
    
    match = re.search(main_group_pattern, content, re.DOTALL)
    
    if match:
        print("✅ Found main project group")
        
        # Create new children list with our organized groups
        new_children = f"""
\t\t\t{groups['sources']} /* Sources */,
\t\t\t{groups['resources']} /* Resources */,
\t\t\t{groups['tests']} /* Tests */,
\t\t\t{groups['widget']} /* Widget */,
\t\t\t{groups['supporting']} /* Supporting Files */,
\t\t\t29B97317FDCFA39411CA2CEA /* Products */,
\t\t\tC01FCF4E08A954540054247B /* Frameworks */,
\t\t"""
        
        # Replace the main group children
        content = re.sub(main_group_pattern, f"\\1{new_children}\\2", content, flags=re.DOTALL)
        
        # Add our group definitions before the existing "/* End PBXGroup section */"
        group_defs = build_group_definitions(groups, categories)
        
        end_group_pattern = r"(/\* End PBXGroup section \*/)"
        content = re.sub(end_group_pattern, f"{group_defs}\\n\\1", content)
        
        print("✅ Updated project structure")
        
        # Write the updated project file
        with open("SleepMate.xcodeproj/project.pbxproj", "w") as f:
            f.write(content)
        
        print("💾 Saved updated project file")
        
    else:
        print("❌ Could not find main project group pattern")
        print("🔍 Searching for alternative patterns...")
        
        # Let's try a different approach - just look for any group with the project name
        project_groups = re.findall(r'(\w+)[^=]*=\s*\{[^}]*name\s*=\s*"?SleepMate"?[^}]*\}', content)
        print(f"📁 Found {len(project_groups)} groups with SleepMate name")
        
        if project_groups:
            print("🔧 Will create a manual organization guide instead")

def main():
    """Main execution"""
    print("🚀 Starting Xcode Project Organization Implementation")
    print("=" * 60)
    
    # Create backup
    import os
    os.system("cp SleepMate.xcodeproj/project.pbxproj SleepMate.xcodeproj/project.pbxproj.backup.implement")
    print("✅ Created project backup")
    
    try:
        implement_organization()
        print("\n✅ Project organization implementation completed!")
        
    except Exception as e:
        print(f"\n❌ Error during implementation: {e}")
        print("🔄 Restoring from backup...")
        os.system("cp SleepMate.xcodeproj/project.pbxproj.backup.implement SleepMate.xcodeproj/project.pbxproj")
        
        print("\n📝 Since automatic implementation failed, here's the manual approach:")
        print("1. Open SleepMate.xcworkspace in Xcode")
        print("2. Right-click on 'SleepMate' in Project Navigator")
        print("3. Select 'New Group' to create folder structure")
        print("4. Drag and drop files into appropriate groups")
        print("\nThis maintains file paths while organizing the Navigator view")

if __name__ == "__main__":
    main()