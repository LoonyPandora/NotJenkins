(function (NotJenkins) {
    "use strict";

    NotJenkins.Model = {
        Builds: Harbour.Model.extend({

        }),
        PullRequest: Harbour.Model.extend({
            idAttribute: "github_number",
            urlRoot: "/api/NotJenkins/pull_requests"
        })
    };

})(Harbour.Module.register("NotJenkins"));
