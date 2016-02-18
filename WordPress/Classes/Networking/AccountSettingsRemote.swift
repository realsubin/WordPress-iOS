import AFNetworking
import Foundation
import RxSwift

class AccountSettingsRemote: ServiceRemoteREST {
    static let remotes = NSMapTable(keyOptions: .StrongMemory, valueOptions: .WeakMemory)

    /// Returns an AccountSettingsRemote with the given api, reusing a previous
    /// remote if it exists.
    static func remoteWithApi(api: WordPressComApi) -> AccountSettingsRemote {
        // We're hashing on the authToken because we don't want duplicate api
        // objects for the same account.
        //
        // In theory this would be taken care of by the fact that the api comes
        // from a WPAccount, and since WPAccount is a managed object Core Data
        // guarantees there's only one of it.
        // 
        // However it might be possible that the account gets deallocated and
        // when it's fetched again it would create a different api object.
        let key = api.authToken.hashValue
        // FIXME: not thread safe
        // @koke 2016-01-21
        if let remote = remotes.objectForKey(key) {
            return remote as! AccountSettingsRemote
        } else {
            let remote = AccountSettingsRemote(api: api)
            remotes.setObject(remote, forKey: key)
            return remote
        }
    }

    let settings: Observable<AccountSettings>

    /// Creates a new AccountSettingsRemote. It is recommended that you use AccountSettingsRemote.remoteWithApi(_)
    /// instead.
    override init(api: WordPressComApi) {
        settings = AccountSettingsRemote.settingsWithApi(api)
        super.init(api: api)
    }

    private static func settingsWithApi(api: WordPressComApi) -> Observable<AccountSettings> {
        let settings = Observable<AccountSettings>.create { observer in
            let remote = AccountSettingsRemote.remoteWithApi(api)
            let lastSettings = remote.getSettingsObservable()
            return lastSettings.subscribe(observer)
        }

        return settings
    }

    var lastSettings = PublishSubject<AccountSettings>()
    var getOperation: AFHTTPRequestOperation? = nil
    var updateOperation: AFHTTPRequestOperation? = nil
    var pendingChanges = [AccountSettingsChange]()

    func getSettingsObservable() -> Observable<AccountSettings> {
        if updateOperation == nil && getOperation == nil {
            getOperation = requestGetSettings()
        }
        return lastSettings
    }

    func getSettings(success: AccountSettings -> Void, failure: ErrorType -> Void) {
        let lastSettings = getSettingsObservable()
        _ = lastSettings.subscribe(onNext: success, onError: failure)
    }

    func updateSetting(change: AccountSettingsChange, success: () -> Void, failure: ErrorType -> Void) {
        pendingChanges.append(change)
        getOperation?.cancel()
        getOperation = nil
        updateOperation?.cancel()
        updateOperation = nil
        _ = lastSettings.subscribe(onNext: { _ in success() }, onError: failure)
        updateOperation = requestUpdatePendingChanges()
    }

    private func requestUpdatePendingChanges() -> AFHTTPRequestOperation? {
        let parameters = pendingChanges.reduce([String: AnyObject]()) { (var params, change) in
            params[fieldNameForChange(change)] = change.stringValue
            return params
        }
        return requestUpdateSettingWithParameters(parameters)
    }

    private func receivedSettingsJSON(responseObject: AnyObject) {
        do {
            let settings = try self.settingsFromResponse(responseObject)
            receivedSettings(settings)
        } catch {
            receivedError(error)
        }
    }

    private func receivedSettings(settings: AccountSettings) {
        lastSettings.onNext(settings)
        lastSettings.onCompleted()
        resetLastSettingsSubject()
    }

    private func receivedError(error: ErrorType) {
        lastSettings.onError(error)
        resetLastSettingsSubject()
    }

    private func resetLastSettingsSubject() {
        lastSettings = PublishSubject<AccountSettings>()
    }

    private func requestGetSettings() -> AFHTTPRequestOperation? {
        let endpoint = "me/settings"
        let parameters = ["context": "edit"]
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        return api.GET(path,
            parameters: parameters,
            success: {
                [weak self] _, responseObject in
                self?.receivedSettingsJSON(responseObject)
            },
            failure: { [weak self] _, error in
                self?.receivedError(error)
        })
    }

    private func requestUpdateSettingWithParameters(parameters: [String: AnyObject]) -> AFHTTPRequestOperation? {
        let endpoint = "me/settings"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        return api.POST(path,
            parameters: parameters,
            success: {
                [weak self] _, responseObject in
                self?.receivedSettingsJSON(responseObject)
            },
            failure: { [weak self] _, error in
                self?.receivedError(error)
        })
    }

    private func settingsFromResponse(responseObject: AnyObject) throws -> AccountSettings {
        guard let
            response = responseObject as? [String: AnyObject],
            firstName = response["first_name"] as? String,
            lastName = response["last_name"] as? String,
            displayName = response["display_name"] as? String,
            aboutMe = response["description"] as? String,
            username = response["user_login"] as? String,
            email = response["user_email"] as? String,
            primarySiteID = response["primary_site_ID"] as? Int,
            webAddress = response["user_URL"] as? String,
            language = response["language"] as? String else {
                DDLogSwift.logError("Error decoding me/settings response: \(responseObject)")
                throw Error.DecodeError
        }

        let aboutMeText = aboutMe.stringByDecodingXMLCharacters()

        return AccountSettings(firstName: firstName, lastName: lastName, displayName: displayName, aboutMe: aboutMeText, username: username, email: email, primarySiteID: primarySiteID, webAddress: webAddress, language: language)
    }

    private func fieldNameForChange(change: AccountSettingsChange) -> String {
        switch change {
        case .FirstName(_):
            return "first_name"
        case .LastName(_):
            return "last_name"
        case .DisplayName(_):
            return "display_name"
        case .AboutMe(_):
            return "description"
        case .Email(_):
            return "email"
        case .PrimarySite(_):
            return "primary_site_ID"
        case .WebAddress(_):
            return "user_URL"
        case .Language(_):
            return "language"
        }
    }
    
    enum Error: ErrorType {
        case DecodeError
    }
}
