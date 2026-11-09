import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.walking_challenge_enabled) {
    return;
  }

  api.addCommunitySectionLink({
    name: "walking-challenge",
    route: "walk",
    text: i18n("walking_challenge.nav_link"),
    title: i18n("walking_challenge.nav_link"),
    icon: "person-walking",
  });
});
