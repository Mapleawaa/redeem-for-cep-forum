import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "redeem-for-cep-forum",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const currentUser = container.lookup("service:current-user");

    if (!currentUser || !siteSettings.cep_redeem_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addCommunitySectionLink(
        {
          name: "rewards",
          href: "/my/preferences/profile#cep-rewards",
          text: i18n("redeem_for_cep_forum.sidebar_label"),
          title: i18n("redeem_for_cep_forum.sidebar_label"),
          icon: "gift",
        },
        true
      );
    });
  },
};
