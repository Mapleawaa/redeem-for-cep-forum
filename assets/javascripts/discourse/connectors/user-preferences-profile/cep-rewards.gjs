import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class CepRewards extends Component {
  @tracked rewards = null;
  @tracked redeemCode = null;
  @tracked error = null;
  @tracked loading = false;
  @tracked redeemingKey = null;

  constructor() {
    super(...arguments);
    this.loadRewards();
  }

  get hasRewards() {
    return this.rewards?.length > 0;
  }

  async loadRewards() {
    this.loading = true;
    this.error = null;

    try {
      const payload = await ajax("/redeem-for-cep-forum/rewards.json");
      this.rewards = payload.rewards || [];
    } catch {
      this.error = "奖励加载失败";
    } finally {
      this.loading = false;
    }
  }

  @action
  async redeem(reward) {
    this.error = null;
    this.redeemCode = null;
    this.redeemingKey = reward.key;

    try {
      const payload = await ajax(
        `/redeem-for-cep-forum/rewards/${reward.key}/redeem.json`,
        {
          type: "POST",
        }
      );
      this.redeemCode = payload.code;
      await this.loadRewards();
    } catch {
      this.error = "领取失败";
    } finally {
      this.redeemingKey = null;
    }
  }

  <template>
    <section id="cep-rewards" class="cep-rewards-preferences">
      <h2>Rewards</h2>
      <p>领取论坛奖励兑换码，然后前往 CEP 前端「我的」页面兑换。</p>

      {{#if this.error}}
        <div class="alert alert-error">{{this.error}}</div>
      {{/if}}

      {{#if this.redeemCode}}
        <div class="alert alert-info">
          <strong>兑换码：</strong>
          <code>{{this.redeemCode}}</code>
          <p>兑换码只显示这一次。离开页面后不会再次展示。</p>
        </div>
      {{/if}}

      {{#if this.loading}}
        <p>正在加载奖励...</p>
      {{else if this.hasRewards}}
        <div class="cep-rewards-preferences__grid">
          {{#each this.rewards as |reward|}}
            <article class="cep-rewards-preferences__card">
              <div>
                <h3>{{reward.title}}</h3>
                <p>{{reward.description}}</p>
                <span>{{reward.trial_days}} 天</span>
              </div>

              {{#if reward.claimed}}
                <button class="btn" type="button" disabled>已领取</button>
              {{else if reward.eligible}}
                <button
                  class="btn btn-primary"
                  type="button"
                  disabled={{eq this.redeemingKey reward.key}}
                  {{on "click" (fn this.redeem reward)}}
                >
                  领取
                </button>
              {{else}}
                <button class="btn" type="button" disabled>
                  {{reward.locked_label}}
                </button>
              {{/if}}
            </article>
          {{/each}}
        </div>
      {{else}}
        <p>暂无奖励。</p>
      {{/if}}
    </section>
  </template>
}
