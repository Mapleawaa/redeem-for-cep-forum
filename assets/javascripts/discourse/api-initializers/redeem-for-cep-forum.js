import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer("1.34.0", (api) => {
  if (!api.container.lookup("service:site-settings").cep_redeem_enabled) {
    return;
  }

  api.addCommunitySectionLink({
    name: "redeem-for-cep-forum-rewards",
    route: "redeemForCepForum.index",
    text: i18n("redeem_for_cep_forum.sidebar_label"),
    title: i18n("redeem_for_cep_forum.sidebar_label"),
    icon: "gift",
  });
});
