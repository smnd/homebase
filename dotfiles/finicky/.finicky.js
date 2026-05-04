export default {
    defaultBrowser: "Google Chrome:Suman",
    options: {
        // Check for updates. Default: true
        checkForUpdates: false,
        // Log every request to file. Default: false
        logRequests: false,
        // Keep Finicky running in the background
        keepRunning: true,
        // Hide the Finicky icon from the menu bar
        hideIcon: true
    },
    // Personal
    handlers: [
        // Open links directly in supported apps
        {
            match: ["*.figma.com/file/*", "*.figma.com/deck/*", "*.figma.com/proto/*", "*.figma.com/design/*", "*.figma.com/*"],
            browser: "Figma",
        },
        {
            match: ["*.notion.so/*"],
            browser: "Notion"
        },
        {
            match: finicky.matchHostnames("open.spotify.com"),
            browser: "Spotify"
        },
        {
            match: /zoom\.us\/join/,
            browser: "us.zoom.xos"
        },
        {
            match: finicky.matchHostnames(['teams.microsoft.com']),
            browser: 'com.microsoft.teams2',
            url: ({ url }) =>
                ({ ...url, protocol: 'msteams' }),
        },
        {
            match:
                [
                "*.myfave.com/*",
                "*.sharepoint.com/*",
                "*.atlassian.net/*",
                "*.turbohire.co/*",
                "mobbin.com/*",
                "click.figma.com/*",
                "*.datadoghq.com/*",
                "*.clevertap.com/*",
                "*.woohoo.com/*",
                "*.woohoo.in/*",
                "*.darwinbox.com/*",
                "analytics.google.com/*",
                "notifications.googleapis.com/*",
                "outlook.office365.com/*",
                "*.google.com/*",
                "pay.weixin.qq.com/*",
                "*.pinelabs.com/*",
                "*.databricks.com/*",
                "*.branch.io/*"
                ],
            browser: "Google Chrome:Work"
        }
    ]
};
