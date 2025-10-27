export default {
    defaultBrowser: {
        name: "Google Chrome",
        profile: "Suman"
    }, // Personal
    handlers: [
        // Open links directly in supported apps
        {
            match: ["*.figma.com/file/*", "*.figma.com/deck/*", "*.figma.com/proto/*", "*.figma.com/design/*"],
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
            // Work links
            match: [
                "*.myfave.com/*", 
                "*.sharepoint.com/*", 
                "*.atlassian.net/*",
                "*.turbohire.co/*",
                "mobbin.com/*",
                "click.figma.com/*",
                "*.datadoghq.com/*"
            ],
            browser: "Google Chrome:Work"
        }
    ]
};
