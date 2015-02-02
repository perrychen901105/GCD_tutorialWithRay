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
    var downloadGroup = dispatch_group_create()
    
    for address in [OverlyAttachedGirlfriendURLString, SuccessKidURLString, LotsOfFacesURLString] {
      let url = NSURL(string: address)
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
  }

  private func postContentAddedNotification() {
    NSNotificationCenter.defaultCenter().postNotificationName(PhotoManagerAddedContentNotification, object: nil)
  }
}
