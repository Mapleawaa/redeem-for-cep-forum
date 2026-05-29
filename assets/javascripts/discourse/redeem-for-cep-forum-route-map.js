export default {
  resource: "redeemForCepForum",
  path: "/rewards",
  map() {
    this.route("index", { path: "/" });
  },
};
