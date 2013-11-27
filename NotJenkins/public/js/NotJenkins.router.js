(function (NotJenkins) {
    "use strict";

    NotJenkins.Router = Harbour.Router.extend({
        routes: {
            "/notjenkins":"index"
        },

        index: function () {
            console.log("notjenkins");
        }
    });

})(Harbour.Module.register("NotJenkins"));
