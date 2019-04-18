//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

class DownloadStickerOperation: OWSOperation {

    private let success: (Data) -> Void
    private let failure: (Error) -> Void
    private let packId: Data
    private let packKey: Data
    private let stickerId: UInt32

    @objc public required init(packId: Data,
                               packKey: Data,
                               stickerId: UInt32,
                               success : @escaping (Data) -> Void,
                               failure : @escaping (Error) -> Void) {
        assert(packId.count > 0)
        assert(packKey.count > 0)

        self.success = success
        self.failure = failure
        self.packId = packId
        self.packKey = packKey
        self.stickerId = stickerId

        super.init()

        self.remainingRetries = 10
    }

    // MARK: Dependencies

    private var cdnSessionManager: AFHTTPSessionManager {
        return OWSSignalService.sharedInstance().cdnSessionManager
    }

    var firstAttempt = true

    override public func run() {

        // https://cdn.signal.org/stickers/<pack_id>/full/<sticker_id>
        let urlPath = "stickers/\(packId.hexadecimalString)/full/\(stickerId)"
        cdnSessionManager.get(urlPath,
                              parameters: nil,
                              progress: { (_) in
                                // Do nothing.
        },
                              success: { [weak self] (_, response) in
                                guard let self = self else {
                                    return
                                }
                                guard let data = response as? Data else {
                                    owsFailDebug("Unexpected response: \(type(of: response))")
                                    return
                                }
                                Logger.verbose("Download succeeded.")
                                self.success(data)
                                self.didSucceed()
        }) { [weak self] (_, error) in
            guard let self = self else {
                return
            }
            Logger.error("Download failed: \(error)")
            self.failureCount += 1
            self.reportError(error)
        }
    }

    override public func didFail(error: Error) {
        Logger.error("Download exhausted retries: \(error)")

        failure(error)
    }

    private var failureCount: UInt = 0

    override public func retryInterval() -> TimeInterval {
        // Arbitrary backoff factor...
        // With backOffFactor of 1.9
        // try  1 delay:  0.00s
        // try  2 delay:  0.19s
        // ...
        // try  5 delay:  1.30s
        // ...
        // try 11 delay: 61.31s
        let backoffFactor = 1.9
        let maxBackoff = kHourInterval

        let seconds = 0.1 * min(maxBackoff, pow(backoffFactor, Double(self.failureCount)))
        return seconds
    }
}
