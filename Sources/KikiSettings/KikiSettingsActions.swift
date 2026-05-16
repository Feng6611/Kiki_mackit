import KikiCore

public enum KikiSettingsActions {
    public static func openURL(_ urlString: String) {
        KikiURLActions.open(urlString)
    }
}
