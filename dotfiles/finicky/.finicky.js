export default {
    defaultBrowser: {
        name: "Dia",
        profile: "Default"
    }, // Personal
    handlers: [
        // Open links directly in supported apps
        {
            match: ["*.figma.com/file/*", "*.figma.com/deck/*", "*.figma.com/proto/*"],
            browser: "Figma",
        },
        {
            match: ["*.notion.so/*"],
            browser: "Notion"
        },
        {
            match: finicky.matchDomains("open.spotify.com"),
            browser: "Spotify"
        },
        {
            match: /zoom\.us\/join/,
            browser: "us.zoom.xos"
        },
        {
            match: finicky.matchHostnames(['teams.microsoft.com']),
            browser: 'com.microsoft.teams',
            url: ({ url }) =>
                ({ ...url, protocol: 'msteams' }),
        },

        // Route URLs to specific browser:profiles
        {
            match: [
                "*.atlassian.net/*",
                "*.atlassian.com/*",
            ],
            browser: {
                name: "Dia",
                appType: "appName",
                profile: "Profile 1",
                openInBackground: true,
            },
        }
    ],
    rewrite: [{
        match: ({
            url
        }) => url.host.includes("zoom.us") && url.pathname.includes("/j/"),
        url({
            url
        }) {
            try {
                var pass = '&pwd=' + url.search.match(/pwd=(\w*)/)[1];
            } catch {
                var pass = ""
            }
            var conf = 'confno=' + url.pathname.match(/\/j\/(\d+)/)[1];
            return {
                search: conf + pass,
                pathname: '/join',
                protocol: "zoommtg"
            }
        }
    }]
};
