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
            match: finicky.matchHostnames(["access.myfave.com*"]),
            browser: 'company.thebrowser.dia'
        },

        // Route URLs to specific browser:profiles
        {
            match: finicky.matchHostnames(['*.sharepoint.com/*']),
            browser: {
                name: "Dia",
            },
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
        }
    ]
};
