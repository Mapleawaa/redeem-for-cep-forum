import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class RedeemForCepForumIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/redeem-for-cep-forum/rewards");
  }
}
