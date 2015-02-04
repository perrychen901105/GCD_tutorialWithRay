//
//  PhotoManager.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 06.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import Foundation

/// Notification when new photo instances are added
let PhotoManagerAddedContentNotification = "com.raywenderlich.GooglyPuff.PhotoManagerAddedContent"
/// Notification when content updates (i.e. Download finishes)
let PhotoManagerContentUpdateNotification = "com.raywenderlich.GooglyPuff.PhotoManagerContentUpdate"

typealias PhotoProcessingProgressClosure = (completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (error: NSError?) -> Void

private let _sharedManager = PhotoManager()

class PhotoManager {
  class var sharedManager: PhotoManager {
    return _sharedManager
  }

  private var _photos: [Photo] = []
  private let concurrentPhotoQueue = dispatch_queue_create("com.raywenderlich.GooglyPuff.photoQueue", DISPATCH_QUEUE_CONCURRENT)
  var photos: [Photo] {
    // FIXME: Not thread-safe
    var photosCopy: [Photo]!
    // dispatch synchronously onto the concurentPhotoQueue to perform the read
    dispatch_sync(concurrentPhotoQueue, { () -> Void in
      // store a copy of the photo array in photosCopy and return it
      photosCopy = self._photos
    })
    return photosCopy
  }

  func addPhoto(photo: Photo) {
    // FIXME: Not thread-safe
    // add the write operation using your custom queue. When the critical section executes at a later time this will be the only item in your queue to execute.
    dispatch_barrier_async(concurrentPhotoQueue, { () -> Void in
      // actual code which adds the object to the array. Since it's a barrier closure. this closure will never run simultaneously with any other closure in concurrentPhotoQueue.
      self._photos.append(photo)
      dispatch_async(dispatch_get_main_queue()) {
        self.postContentAddedNotification()
      }

    })
    
  }

  func downloadPhotosWithCompletion(completion: BatchPhotoDownloadingCompletionClosure?) {
    
    var storedError: NSError!
    let downloadGroup = dispatch_group_create()
    var addresses = [OverlyAttachedGirlfriendURLString, SuccessKidURLString, LotsOfFacesURLString]
    addresses += addresses + addresses // 1
    var blocks: [dispatch_block_t] = [] // 2
    
    for i in 0 ..< addresses.count {
      dispatch_group_enter(downloadGroup)
      // 3
      /*
        creates a new block object. first parameter is a flag defining various block traits. The flag used here makes the block inherit its QoS class from the queue it is dispatched to. The second parameter is the block definition in the form of a closure.
      */
      let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, { () -> Void in
        let index = Int(i)
        let address = addresses[index]
        let url = NSURL(string: address)
        let photo = DownloadPhoto(url: url!) {
          image, error in
          if let error = error {
            storedError = error
          }
          dispatch_group_leave(downloadGroup)
        }
        PhotoManager.sharedManager.addPhoto(photo)
      })
      blocks.append(block)
      dispatch_async(GlobalMainQueue, block) // 4
    }
    
    for block in blocks[3 ..< blocks.count] { // 5
      let cancel = arc4random_uniform(2) // 6
      if cancel == 1 {
        dispatch_block_cancel(block) // 7
        dispatch_group_leave(downloadGroup) // 8
      }
    }
    
    dispatch_group_notify(downloadGroup, GlobalMainQueue) { () -> Void in
      if let completion = completion {
        completion(error: storedError)
      }
    }
    
    /*
    // dispatch_group_wait
    // since using the synchronous dispatch_group_wait which blocks the current thread, you use dispatch_async to place the entire method into a background queue to ensure you don't block the main thread
    dispatch_async(GlobalUserInitiatedQueue) { // 1
      var storedError: NSError!
      // Create a new dispatch group which behaves somewhat like a counter of the number of uncompleted tasks.
      var downloadGroup = dispatch_group_create() // 2
      
      for address in [OverlyAttachedGirlfriendURLString, SuccessKidURLString, LotsOfFacesURLString] {
        let url = NSURL(string: address)
        // manually notifies a group that a task has started. You must balance out the number of dispatch_group_enter calls with the number of dispatch_group_leave calls or else your app will crash.
        dispatch_group_enter(downloadGroup) // 3
        let photo = DownloadPhoto(url: url!) {
          image, error in
          if let error = error {
            storedError = error
          }
          dispatch_group_leave(downloadGroup) // 4
        }
        PhotoManager.sharedManager.addPhoto(photo)
      }
      dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER) // 5
      dispatch_async(GlobalMainQueue, { () -> Void in
        if let completion = completion { // 7
          completion(error: storedError)
        }
      })
    }
    */
    /* 
    // dispatch_apply
    var storedError: NSError!
    var downloadGroup = dispatch_group_create()
    let address = [OverlyAttachedGirlfriendURLString, SuccessKidURLString, LotsOfFacesURLString]
    
    // returns only when all of the work is done.
    dispatch_apply(UInt(address.count), GlobalUserInitiatedQueue) { (i) -> Void in
      let index = Int(i)
      let address = address[index]
      let url = NSURL(string: address)
      dispatch_group_enter(downloadGroup)
      let photo = DownloadPhoto(url: url!) {
        image, error in
        if let error = error {
          storedError = error
        }
        dispatch_group_leave(downloadGroup)
      }
      PhotoManager.sharedManager.addPhoto(photo)
    }
    
    dispatch_group_notify(downloadGroup, GlobalMainQueue) { () -> Void in
      if let completion = completion {
        completion(error: storedError)
      }
    }
    */
  }

  private func postContentAddedNotification() {
    NSNotificationCenter.defaultCenter().postNotificationName(PhotoManagerAddedContentNotification, object: nil)
  }
}
