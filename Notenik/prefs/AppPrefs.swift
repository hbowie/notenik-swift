//
//  AppPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Act as an intermediary between various Application classes and the UserDefaults
class AppPrefs {
    
    /// Provide a standard shared singleton instance
    static let shared = AppPrefs()
    
    let defaults = UserDefaults.standard
    
    let launchingKey    = "app-launching"
    let quickDeletesKey = "quick-deletes"
    let fontSizeKey     = "font-size"
    let tagsSelectKey   = "tags-to-select"
    let tagsSuppressKey = "tags-to-suppress"
    let parentRealmParentKey = "parent-realm-parent"
    let useCountKey     = "use-count"
    let lastVersionPromptedForReviewKey = "last-version-prompted-for-review"
    
    let favoritesColumnsKey = "favorites-columns"
    let favoritesRowsKey = "favorites-rows"
    let favoritesColumnWidthKey = "favorites-column-width"
    
    let markdownParserKey = "markdown-parser"
    
    let essentialURLKey = "essential-collection"
    var _essentialURL: URL?
    
    let lastURLKey = "last-collection"
    var _lastURL: URL?
    
    var _appLaunching = false
    
    var _qd: Bool = false
    
    var _edFS:   Float   = 13.0
    var _edFSCG: CGFloat = 13.0
    
    var _prp = ""
    var parentRealmPath = ""
    
    var userFont       = NSFont.userFont(ofSize: 13.0)
    var fixedPitchFont = NSFont.userFixedPitchFont(ofSize: 13.0)
    
    var userFontAttrs       = [NSAttributedString.Key.font: NSFont.userFont(ofSize: 13.0)]
    var fixedPitchFontAttrs = [NSAttributedString.Key.font: NSFont.userFixedPitchFont(ofSize: 13.0)]
    
    var pickLists = ValuePickLists()
    
    var _tsel = ""
    var _tsup = ""
    
    var _uc = 0
    
    var _lvpfr = ""
    var currentVersion = ""
    
    var _favCols = 0
    var _favRows = 0
    var _favColWidth = "250px"
    
    var newVersionForReview = false
    
    var _mdParser = "down"
    
    var locale: Locale!
    var languageCode = "en"
    var localeID: String!
    var americanEnglish = true
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        
        // Retrieve and log info about the current app.
        if let infoDictionary = Bundle.main.infoDictionary {
            let version = infoDictionary["CFBundleShortVersionString"] as? String
            let build   = infoDictionary[kCFBundleVersionKey as String] as? String
            let appName = infoDictionary[kCFBundleNameKey as String] as? String
            
            if appName != nil {
                logInfo("Launching \(appName!)")
            }
            
            if version != nil {
                currentVersion = version!
                logInfo("Version \(currentVersion)")
            }
            
            if build != nil {
                logInfo("Build # \(build!)")
            }
        }
        
        /// Check a prefs flag to see if we successfully completed launching
        /// last time around; if not, then reset to initial defaults.
        _appLaunching = defaults.bool(forKey: launchingKey)
        if appLaunching {
            resetDefaults()
        } else {
            appLaunching = true
            loadDefaults()
        }
    }
    
    func resetDefaults() {
        confirmDeletes = true
        resetEditFontSize()
        deriveRelatedFontFields()
        parentRealmParent = ""
        useCount = 0
        favoritesColumns = 4
        favoritesRows = 32
        favoritesColumnWidth = "250px"
        markdownParser = "down"
    }
    
    func loadDefaults() {
        
        _essentialURL = defaults.url(forKey: essentialURLKey)
        
        _lastURL = defaults.url(forKey: lastURLKey)
        
        _qd = defaults.bool(forKey: quickDeletesKey)
        
        let defaultFontSize = defaults.float(forKey: fontSizeKey)
        if defaultFontSize == 0.0 {
            defaults.set(_edFS, forKey: fontSizeKey)
        } else {
            _edFS = defaultFontSize
        }
        deriveRelatedFontFields()
        
        let tsel = defaults.string(forKey: tagsSelectKey)
        if tsel != nil {
            _tsel = tsel!
        }
        let tsup = defaults.string(forKey: tagsSuppressKey)
        if tsup != nil {
            _tsup = tsup!
        }
        
        let defaultprp = defaults.string(forKey: parentRealmParentKey)
        if defaultprp != nil {
            _prp = defaultprp!
        }
        
        _uc = defaults.integer(forKey: useCountKey)
        
        // Get the Last Version Prompted for Review.
        let lvpfr = defaults.string(forKey: lastVersionPromptedForReviewKey)
        if lvpfr != nil {
            _lvpfr = lvpfr!
        }
        
        // Now see if we have a new version for review.
        newVersionForReview = currentVersion > lastVersionPromptedForReview
        
        // Get Favorites Defaults
        _favCols = defaults.integer(forKey: favoritesColumnsKey)
        _favRows = defaults.integer(forKey: favoritesRowsKey)
        if _favCols == 0 {
            _favCols = 4
        }
        if _favRows == 0 {
            _favRows = 32
        }
        let favColWidth = defaults.string(forKey: favoritesColumnWidthKey)
        if favColWidth != nil {
            _favColWidth = favColWidth!
        }
        
        // Get Markdown Parser defaults
        let mdParserDefault = defaults.string(forKey: markdownParserKey)
        if mdParserDefault != nil {
            _mdParser = mdParserDefault!
        }
        
        // American English? (Or British?)
        locale = Locale.current
        localeID = locale.identifier
        if locale.languageCode != nil {
            languageCode = locale.languageCode!
        }
        if languageCode == "en" {
            americanEnglish = (localeID == "en_US" || localeID == "en_PH" || localeID == "en_UM" || localeID == "en_US_POSIX" || localeID == "en_AS" || localeID == "en_VI")
        }
        if localeID != nil {
            logInfo("Locale identifier is \(localeID!)")
        }
        if locale.regionCode != nil {
            logInfo("Region code is \(locale.regionCode!)")
        }
        logInfo("Language code is \(languageCode)")
        if americanEnglish {
            logInfo("Using American English")
        } else {
            logInfo("Using UK/British English")
        }
    }
    
    /// Has the app made it out of the launching phase successfully?
    var appLaunching: Bool {
        get {
            return _appLaunching
        }
        set {
            _appLaunching = newValue
            defaults.set(newValue, forKey: launchingKey)
        }
    }
    
    var essentialURL: URL? {
        get {
            return _essentialURL
        }
        set {
            _essentialURL = newValue
            defaults.set(_essentialURL, forKey: essentialURLKey)
        }
    }
    
    var lastURL: URL? {
        get {
            return _lastURL
        }
        set {
            _lastURL = newValue
            defaults.set(_lastURL, forKey: lastURLKey)
        }
    }
    
    var confirmDeletes: Bool {
        get {
            return !_qd
        }
        set {
            _qd = !newValue
            defaults.set(_qd, forKey: quickDeletesKey)
        }
    }
    
    var editFontSize: Float {
        get {
            return _edFS
        }
        set {
            if newValue > 8.0 && newValue < 24.0 {
                _edFS = newValue
                defaults.set(_edFS, forKey: fontSizeKey)
                deriveRelatedFontFields()
            }
        }
    }
    
    var parentRealmParent: String {
        get {
            return _prp
        }
        set {
            _prp = newValue
            defaults.set(_prp, forKey: parentRealmParentKey)
        }
    }
    
    var parentRealmParentURL: URL? {
        get {
            if _prp.count > 0 {
                return URL(fileURLWithPath: _prp)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                _prp = newValue!.path
                defaults.set(_prp, forKey: parentRealmParentKey)
            }
        }
    }
    
    /// Prepare all the font fields we might need, adjusted to the latest size selection
    func deriveRelatedFontFields() {
        
        _edFSCG = CGFloat(_edFS)
        
        userFont = NSFont.userFont(ofSize: _edFSCG)
        fixedPitchFont = NSFont.userFixedPitchFont(ofSize: _edFSCG)
        
        userFontAttrs = [NSAttributedString.Key.font: userFont]
        fixedPitchFontAttrs = [NSAttributedString.Key.font: fixedPitchFont]
    }
    
    func increaseEditFontSize(by: Float) {
        editFontSize += by
    }
    
    func decreaseEditFontSize(by: Float) {
        editFontSize -= by
    }
    
    func resetEditFontSize() {
        editFontSize = 13.0
    }
    
    func setRegularFont(object: NSObject) {
        if userFont != nil {
            if let cb = object as? NSComboBox {
                cb.font = userFont
            } else if let textView = object as? NSTextView {
                textView.font = userFont
            } else if let textField = object as? NSTextField {
                textField.font = userFont
            } else if let menu = object as? NSMenu {
                menu.font = userFont
            } 
        }
    }
    
    func setFixedPitchFont(view: NSView) {
        if userFont != nil {
            if let textView = view as? NSTextView {
                textView.font = fixedPitchFont
            } else if let textField = view as? NSTextField {
                textField.font = fixedPitchFont
            }
        }
    }
    
    /// Make an attributed string using latest font size
    func makeUserAttributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: userFontAttrs as [NSAttributedString.Key: Any])
    }
    
    /// Determine the appropriate height constraint for a text view based on the desired
    /// Number of lines to show. 
    func getViewHeight(lines: Float) -> CGFloat {
        return CGFloat(editFontSize * 1.20 * lines)
    }
    
    var tagsToSelect: String {
        get {
            return _tsel
        }
        set {
            _tsel = newValue
            defaults.set(_tsel, forKey: tagsSelectKey)
        }
    }
    
    var tagsToSuppress: String {
        get {
            return _tsup
        }
        set {
            _tsup = newValue
            defaults.set(_tsup, forKey: tagsSuppressKey)
        }
    }
    
    /// Add one to the use counter.
    func incrementUseCount() {
        let newUseCount = useCount + 1
        useCount = newUseCount
    }
    
    /// Get and set the number of times the user has used the app. 
    var useCount: Int {
        get {
            return _uc
        }
        set {
            _uc = newValue
            defaults.set(_uc, forKey: useCountKey)
        }
    }
    
    func userPromptedForReview() {
        lastVersionPromptedForReview = currentVersion
    }
    
    var lastVersionPromptedForReview: String {
        get {
            return _lvpfr
        }
        set {
            _lvpfr = newValue
            defaults.set(_lvpfr, forKey: lastVersionPromptedForReviewKey)
        }
    }
    
    var favoritesColumns: Int {
        get { return _favCols }
        set {
            if newValue > 0 {
                _favCols = newValue
                defaults.set(_favCols, forKey: favoritesColumnsKey)
            }
        }
    }
    
    var favoritesRows: Int {
        get { return _favRows }
        set {
            if newValue > 0 {
                _favRows = newValue
                defaults.set(_favRows, forKey: favoritesRowsKey)
            }
        }
    }
    
    var favoritesColumnWidth: String {
        get { return _favColWidth }
        set {
            if newValue.count > 0 {
                _favColWidth = newValue
                defaults.set(_favColWidth, forKey: favoritesColumnWidthKey)
            }
        }
    }
    
    /// get or set the chosen Markdown parser.
    var markdownParser: String {
        get { return _mdParser }
        set {
            switch newValue {
            case "down", "ink":
                _mdParser = newValue
                defaults.set(newValue, forKey: markdownParserKey)
            default:
                break
            }
        }
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppPrefs",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppPrefs",
                          level: .error,
                          message: msg)
    }
}
