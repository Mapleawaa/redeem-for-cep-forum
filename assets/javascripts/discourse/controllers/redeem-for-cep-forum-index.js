import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class RedeemForCepForumIndexController extends Controller {
  @tracked redeemCode = null;
  @tracked redeemingKey = null;
  @tracked error = null;

  get rewards() {
    return this.model?.rewards || [];
  }

  @action
  async redeem(reward) {
    this.error = null;
    this.redeemCode = null;
    this.redeemingKey = reward.key;

    try {
      const result = await ajax(
        `/redeem-for-cep-forum/rewards/${reward.key}/redeem`,
        {
          type: "POST",
        }
      );

      this.redeemCode = result.code;
      this.set("model", await ajax("/redeem-for-cep-forum/rewards"));
    } catch {
      this.error = i18n("redeem_for_cep_forum.errors.redeem_failed");
    } finally {
      this.redeemingKey = null;
    }
  }
}
