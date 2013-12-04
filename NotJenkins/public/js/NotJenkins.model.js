(function (NotJenkins) {
    "use strict";

    NotJenkins.Model = {
        Builds: Harbour.Model.extend({

        }),

        PullRequest: Harbour.Model.extend({
            idAttribute: "github_number",
            urlRoot: "/api/NotJenkins/pull_requests"
        }),

        Branch: Harbour.Model.extend({
            idAttribute: "branch_name",
            urlRoot: "/api/NotJenkins/branches"
        })
        
    };

})(Harbour.Module.register("NotJenkins"));
