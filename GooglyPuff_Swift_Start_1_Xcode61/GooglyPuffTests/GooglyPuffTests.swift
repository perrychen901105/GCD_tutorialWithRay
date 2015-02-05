//
//  GooglyPuffTests.swift
//  GooglyPuffTests
//
//  Created by Bjørn Olav Ruud on 06.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import UIKit
import XCTest

private let DefaultTimeoutLengthInNanoSeconds: Int64 = 10000000000 // 10 Seconds

class GooglyPuffTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testMikeAshImageURL() {
    downloadImageURLWithString(LotsOfFacesURLString)
  }

  func testMattThompsonImageURL() {
    downloadImageURLWithString(SuccessKidURLString)
  }

  func testAaronHillegassImageURL() {
    downloadImageURLWithString(OverlyAttachedGirlfriendURLString)
  }

  func downloadImageURLWithString(urlString: String) {
    let url = NSURL(string: urlString)
    // 1
    let downloadExpectation = expectationWithDescription("Image downloaded from \(urlString)")
    let photo = DownloadPhoto(url: url!) { (image, error) -> Void in
      if let error = error {
        XCTFail("\(urlString) failed. \(error.localizedDescription)")
      }
      downloadExpectation.fulfill()
    }
    waitForExpectationsWithTimeout(10, handler: { (error) -> Void in
      if let error = error {
        XCTFail(error.localizedDescription)
      }
    })
    /*
     /// semaphore
    let url = NSURL(string: urlString)
    /// Create the semaphore. The parameter indicates the value the semaphore starts with. This number is the number of things that can access the semaphore without having to have something increment it first.
    let semaphore = dispatch_semaphore_create(0) // 1
    let photo = DownloadPhoto(url: url!) {
      image, error in
      if let error = error {
        XCTFail("\(urlString) failed. \(error.localizedDescription)")
      }
      /// tell the semaphore that no longer need the resource. This increments the semaphore count and signals that the semaphore is available to other resources that want it.
      dispatch_semaphore_signal(semaphore) // 2
    }
    
    let timeout = dispatch_time(DISPATCH_TIME_NOW, DefaultTimeoutLengthInNanoSeconds)
    // 3
    /// waits on the semaphore, with a given time out.
    if dispatch_semaphore_wait(semaphore, timeout) != 0 {
      XCTFail("\(urlString) time out")
    }
*/
  }

}
