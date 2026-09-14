import XCTest

final class MiniCookpadUITests: XCTestCase {
    @MainActor
    func testAddHashtagAndReturnToList() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["USE_STUB_API_CLIENT"] = "1"
        app.launch()
        let recipe = app.buttons["recipeRow-1"]
        XCTAssertTrue(recipe.waitForExistence(timeout: 10))
        recipe.tap()
        let add = app.buttons["addHashtags"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let input = app.descendants(matching: .any)["hashtagsInput"].firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("#UITestTag")
        app.buttons["saveHashtags"].tap()
        let tags = app.staticTexts["detailHashtags"]
        let updated = NSPredicate(format: "label CONTAINS %@", "#UITestTag")
        expectation(for: updated, evaluatedWith: tags)
        waitForExpectations(timeout: 10)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let updatedRow = app.buttons["recipeRow-1"]
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 10))
        XCTAssertTrue(updatedRow.label.contains("#UITestTag"))
    }
}
