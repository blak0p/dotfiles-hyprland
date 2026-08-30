import QtQuick
import qs.Core.Services
pragma Singleton

Item {
    id: githubService

    property string username: SettingsService.githubUsername
    property string token: SettingsService.githubToken
    property bool hasToken: token !== undefined && token !== ""
    property string avatarUrl: ""
    property string fullName: ""
    property string bio: ""
    property string location: ""
    property int publicRepos: 0
    property int privateRepos: 0
    property int followers: 0
    property int totalStars: 0
    property int totalForks: 0
    property string topRepoName: "..."
    property string topRepoDesc: ""
    property int topRepoStars: 0
    property int topRepoForks: 0
    property string topRepoLang: ""
    property string joinedDate: "..."
    property int totalCommits: 0
    property string topLanguage: "None"
    property bool isFetching: false

    function fetchData() {
        debounceTimer.restart();
    }

    function executeFetch() {
        if (githubService.username === "") {
            githubService.avatarUrl = "";
            githubService.fullName = "";
            githubService.bio = "";
            githubService.location = "";
            githubService.publicRepos = 0;
            githubService.privateRepos = 0;
            githubService.followers = 0;
            githubService.joinedDate = "...";
            githubService.totalStars = 0;
            githubService.totalForks = 0;
            githubService.topRepoName = "...";
            githubService.topRepoDesc = "";
            githubService.topRepoStars = 0;
            githubService.topRepoForks = 0;
            githubService.topRepoLang = "";
            githubService.topLanguage = "None";
            githubService.totalCommits = 0;
            return ;
        }
        githubService.isFetching = true;
        fetchProfile();
        fetchRepos();
        if (githubService.hasToken)
            fetchCommits();
        else
            githubService.totalCommits = 0;
    }

    function fetchProfile() {
        let req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200) {
                    try {
                        let profile = JSON.parse(req.responseText);
                        if (profile.message && profile.message.includes("API rate limit"))
                            return ;

                        if (profile.login) {
                            githubService.avatarUrl = profile.avatar_url || "";
                            githubService.fullName = profile.name || "";
                            githubService.bio = profile.bio || "";
                            githubService.location = profile.location || "";
                            githubService.publicRepos = profile.public_repos || 0;
                            if (githubService.hasToken)
                                githubService.privateRepos = profile.total_private_repos || profile.owned_private_repos || 0;

                            githubService.followers = profile.followers || 0;
                            if (profile.created_at) {
                                let date = new Date(profile.created_at);
                                let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                                githubService.joinedDate = months[date.getMonth()] + " " + date.getFullYear();
                            }
                        }
                    } catch (e) {
                        console.error("Github profile parse error: " + e);
                    }
                }
                checkFetchingComplete();
            }
        };
        let url = githubService.hasToken ? "https://api.github.com/user" : ("https://api.github.com/users/" + githubService.username);
        req.open("GET", url);
        if (githubService.hasToken)
            req.setRequestHeader("Authorization", "token " + githubService.token);

        req.send();
    }

    function fetchRepos() {
        let req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200) {
                    try {
                        let repos = JSON.parse(req.responseText);
                        if (Array.isArray(repos)) {
                            let starsSum = 0;
                            let forksSum = 0;
                            let maxStars = -1;
                            let bestRepoName = "";
                            let bestRepoDesc = "";
                            let bestRepoStars = 0;
                            let bestRepoForks = 0;
                            let bestRepoLang = "";
                            let langCounts = {
                            };
                            for (let i = 0; i < repos.length; i++) {
                                let r = repos[i];
                                if (!r)
                                    continue;

                                starsSum += r.stargazers_count || 0;
                                forksSum += r.forks_count || 0;
                                if (r.stargazers_count > maxStars) {
                                    maxStars = r.stargazers_count;
                                    bestRepoName = r.name;
                                    bestRepoDesc = r.description || "";
                                    bestRepoStars = r.stargazers_count || 0;
                                    bestRepoForks = r.forks_count || 0;
                                    bestRepoLang = r.language || "";
                                }
                                if (r.language)
                                    langCounts[r.language] = (langCounts[r.language] || 0) + 1;

                            }
                            githubService.totalStars = starsSum;
                            githubService.totalForks = forksSum;
                            githubService.topRepoName = bestRepoName || "None";
                            githubService.topRepoDesc = bestRepoDesc;
                            githubService.topRepoStars = bestRepoStars;
                            githubService.topRepoForks = bestRepoForks;
                            githubService.topRepoLang = bestRepoLang;
                            let mostLang = "None";
                            let maxLangCount = 0;
                            for (let lang in langCounts) {
                                if (langCounts[lang] > maxLangCount) {
                                    maxLangCount = langCounts[lang];
                                    mostLang = lang;
                                }
                            }
                            githubService.topLanguage = mostLang;
                        }
                    } catch (e) {
                        console.error("Github repos parse error: " + e);
                    }
                }
                checkFetchingComplete();
            }
        };
        let url = githubService.hasToken ? "https://api.github.com/user/repos?per_page=100&type=owner" : ("https://api.github.com/users/" + githubService.username + "/repos?per_page=100");
        req.open("GET", url);
        if (githubService.hasToken)
            req.setRequestHeader("Authorization", "token " + githubService.token);

        req.send();
    }

    function fetchCommits() {
        let req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200) {
                    try {
                        let search = JSON.parse(req.responseText);
                        if (search && search.total_count !== undefined)
                            githubService.totalCommits = search.total_count;

                    } catch (e) {
                        console.error("Github commits parse error: " + e);
                    }
                }
                checkFetchingComplete();
            }
        };
        req.open("GET", "https://api.github.com/search/commits?q=author:" + githubService.username);
        req.setRequestHeader("Authorization", "token " + githubService.token);
        req.send();
    }

    function checkFetchingComplete() {
        fetchTimer.restart();
    }

    onUsernameChanged: fetchData()
    onTokenChanged: fetchData()

    Timer {
        id: debounceTimer

        interval: 200
        repeat: false
        onTriggered: githubService.executeFetch()
    }

    Timer {
        id: fetchTimer

        interval: 500
        repeat: false
        onTriggered: githubService.isFetching = false
    }

    Timer {
        interval: 600000
        running: githubService.username !== ""
        repeat: true
        onTriggered: githubService.fetchData()
    }

}
