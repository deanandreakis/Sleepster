#!/usr/bin/env python3
"""
Safe Xcode Group Creation
Creates empty groups that can be manually populated in Xcode
"""

import uuid

def generate_xcode_uuid():
    """Generate a valid Xcode UUID"""
    return ''.join(c for c in str(uuid.uuid4()).upper() if c.isalnum())[:24]

def create_safe_groups():
    """Create empty groups safely"""
    
    print("🏗️  Creating safe group structure...")
    
    with open("SleepMate.xcodeproj/project.pbxproj", "r") as f:
        content = f.read()
    
    # Generate UUIDs for our groups
    groups = {
        'sources': generate_xcode_uuid(),
        'app': generate_xcode_uuid(),
        'models': generate_xcode_uuid(),
        'views': generate_xcode_uuid(),
        'view_components': generate_xcode_uuid(),
        'viewmodels': generate_xcode_uuid(),
        'services': generate_xcode_uuid(),
        'managers': generate_xcode_uuid(),
        'utilities': generate_xcode_uuid(),
        'resources_group': generate_xcode_uuid(),
        'audio': generate_xcode_uuid(),
        'images': generate_xcode_uuid(),
        'tests': generate_xcode_uuid(),
        'widget': generate_xcode_uuid(),
        'supporting': generate_xcode_uuid()
    }
    
    # Create the group definitions (empty groups)
    group_definitions = f"""
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
\t\t);
\t\tname = App;
\t\tsourceTree = "<group>";
\t}};
\t{groups['models']} /* Models */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Models;
\t\tsourceTree = "<group>";
\t}};
\t{groups['views']} /* Views */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{groups['view_components']} /* Components */,
\t\t);
\t\tname = Views;
\t\tsourceTree = "<group>";
\t}};
\t{groups['view_components']} /* Components */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Components;
\t\tsourceTree = "<group>";
\t}};
\t{groups['viewmodels']} /* ViewModels */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = ViewModels;
\t\tsourceTree = "<group>";
\t}};
\t{groups['services']} /* Services */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Services;
\t\tsourceTree = "<group>";
\t}};
\t{groups['managers']} /* Managers */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Managers;
\t\tsourceTree = "<group>";
\t}};
\t{groups['utilities']} /* Utilities */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Utilities;
\t\tsourceTree = "<group>";
\t}};
\t{groups['resources_group']} /* Resources */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{groups['audio']} /* Audio */,
\t\t\t{groups['images']} /* Images */,
\t\t);
\t\tname = Resources;
\t\tsourceTree = "<group>";
\t}};
\t{groups['audio']} /* Audio */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Audio;
\t\tsourceTree = "<group>";
\t}};
\t{groups['images']} /* Images */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Images;
\t\tsourceTree = "<group>";
\t}};
\t{groups['tests']} /* Tests */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Tests;
\t\tsourceTree = "<group>";
\t}};
\t{groups['widget']} /* Widget */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = Widget;
\t\tsourceTree = "<group>";
\t}};
\t{groups['supporting']} /* Supporting Files */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t);
\t\tname = "Supporting Files";
\t\tsourceTree = "<group>";
\t}};"""
    
    # Find a safe place to insert our groups - right before the end of PBXGroup section
    insert_point = "/* End PBXGroup section */"
    
    if insert_point in content:
        content = content.replace(insert_point, group_definitions + "\\n" + insert_point)
        print("✅ Added empty group structure")
        
        # Now add these groups to the main project group
        # Find the main project group (29B97314FDCFA39411CA2CEA)
        main_group_pattern = r'(29B97314FDCFA39411CA2CEA[^=]*=\s*\{[^}]*children\s*=\s*\([^)]*)(.*?)(\);[^}]*sourceTree[^}]*\};)'
        
        import re
        match = re.search(main_group_pattern, content, re.DOTALL)
        
        if match:
            # Add our groups to the main group children
            new_children = f"""{match.group(1)}
\t\t\t{groups['sources']} /* Sources */,
\t\t\t{groups['resources_group']} /* Resources */,
\t\t\t{groups['tests']} /* Tests */,
\t\t\t{groups['widget']} /* Widget */,
\t\t\t{groups['supporting']} /* Supporting Files */,{match.group(2)}{match.group(3)}"""
            
            content = re.sub(main_group_pattern, new_children, content, flags=re.DOTALL)
            print("✅ Added groups to main project group")
        
        # Write the updated file
        with open("SleepMate.xcodeproj/project.pbxproj", "w") as f:
            f.write(content)
        
        print("💾 Saved updated project file")
        return True
    
    else:
        print("❌ Could not find safe insertion point")
        return False

def main():
    """Main function"""
    print("🛡️  Creating Safe Xcode Group Structure")
    print("=" * 50)
    
    # Create backup
    import os
    os.system("cp SleepMate.xcodeproj/project.pbxproj SleepMate.xcodeproj/project.pbxproj.backup.safe")
    print("✅ Created project backup")
    
    success = create_safe_groups()
    
    if success:
        print("\\n✅ Safe group structure created!")
        print("📋 Groups created (empty - ready for manual organization):")
        print("   ├── Sources")
        print("   │   ├── App")
        print("   │   ├── Models")
        print("   │   ├── Views")
        print("   │   │   └── Components")
        print("   │   ├── ViewModels")
        print("   │   ├── Services")
        print("   │   ├── Managers")
        print("   │   └── Utilities")
        print("   ├── Resources")
        print("   │   ├── Audio")
        print("   │   └── Images")
        print("   ├── Tests")
        print("   ├── Widget")
        print("   └── Supporting Files")
        print("\\n🔧 Open in Xcode and drag files into the appropriate groups!")
    else:
        print("\\n❌ Failed to create groups safely")
        # Restore backup
        os.system("cp SleepMate.xcodeproj/project.pbxproj.backup.safe SleepMate.xcodeproj/project.pbxproj")

if __name__ == "__main__":
    main()