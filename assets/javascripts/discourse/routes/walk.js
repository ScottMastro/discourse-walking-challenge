import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class WalkRoute extends DiscourseRoute {
  model() {
    return ajax("/walk.json");
  }

  titleToken() {
    return i18n("walking_challenge.title");
  }
}
