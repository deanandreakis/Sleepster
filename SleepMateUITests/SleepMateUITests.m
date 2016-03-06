//
//  SleepMateUITests.m
//  SleepMateUITests
//
//  Created by Dean Andreakis on 3/1/16.
//
//

#import <XCTest/XCTest.h>
#import "SleepMateUITests-Swift.h"

@interface SleepMateUITests : XCTestCase

@end

@implementation SleepMateUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    //[[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [Snapshot setupSnapshot:app];
    [app launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tabBarsQuery = app.tabBars;
    [tabBarsQuery.buttons[@"Main"] tap];
    [Snapshot snapshot:@"01MainScreen" waitForLoadingIndicator:YES];
    [app.buttons[@"Play"] tap];
     //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [Snapshot snapshot:@"02SleepScreen" waitForLoadingIndicator:YES];
    //NSNumber *value2 = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value2 forKey:@"orientation"];
    [app.buttons[@"stop sound and image"] tap];
    [tabBarsQuery.buttons[@"Sounds"] tap];
    [Snapshot snapshot:@"03SoundsScreen" waitForLoadingIndicator:YES];
    [tabBarsQuery.buttons[@"Backgrounds"] tap];
    [Snapshot snapshot:@"04BackgroundsScreen" waitForLoadingIndicator:YES];
    [tabBarsQuery.buttons[@"Settings"] tap];
    [Snapshot snapshot:@"05SettingsScreen" waitForLoadingIndicator:YES];
    [tabBarsQuery.buttons[@"Information"] tap];
    [Snapshot snapshot:@"06InformationScreen" waitForLoadingIndicator:YES];
}

@end
