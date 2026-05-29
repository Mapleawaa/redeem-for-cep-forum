import { fn } from "@ember/helper";
import i18n from "discourse-common/helpers/i18n";

<template>
  <section class="redeem-for-cep-forum">
    <div class="redeem-for-cep-forum__hero">
      <p class="redeem-for-cep-forum__eyebrow">
        {{i18n "redeem_for_cep_forum.title"}}
      </p>
      <h1>{{i18n "redeem_for_cep_forum.title"}}</h1>
    </div>

    {{#if this.error}}
      <div class="alert alert-error">{{this.error}}</div>
    {{/if}}

    {{#if this.redeemCode}}
      <div class="redeem-for-cep-forum__code">
        <span>{{i18n "redeem_for_cep_forum.code_title"}}</span>
        <code>{{this.redeemCode}}</code>
        <p>{{i18n "redeem_for_cep_forum.code_notice"}}</p>
        <p>{{i18n "redeem_for_cep_forum.redeem_at_cep"}}</p>
      </div>
    {{/if}}

    <div class="redeem-for-cep-forum__grid">
      {{#each this.rewards as |reward|}}
        <article class="redeem-for-cep-forum__card">
          <div>
            <h2>{{reward.title}}</h2>
            <p>{{reward.description}}</p>
            <span class="redeem-for-cep-forum__days">
              {{i18n "redeem_for_cep_forum.days" count=reward.trial_days}}
            </span>
          </div>

          {{#if reward.claimed}}
            <button class="btn" type="button" disabled>
              {{i18n "redeem_for_cep_forum.claimed"}}
            </button>
          {{else if reward.eligible}}
            <button
              class="btn btn-primary"
              type="button"
              disabled={{eq this.redeemingKey reward.key}}
              {{on "click" (fn this.redeem reward)}}
            >
              {{i18n "redeem_for_cep_forum.redeem"}}
            </button>
          {{else}}
            <button class="btn" type="button" disabled>
              {{#if (eq reward.locked_reason "cep_user_not_bound")}}
                {{i18n "redeem_for_cep_forum.reasons.cep_user_not_bound"}}
              {{else if (eq reward.locked_reason "not_eligible")}}
                {{i18n "redeem_for_cep_forum.reasons.not_eligible"}}
              {{else}}
                {{i18n "redeem_for_cep_forum.locked"}}
              {{/if}}
            </button>
          {{/if}}
        </article>
      {{/each}}
    </div>
  </section>
</template>
