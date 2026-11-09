import { trustHTML } from "@ember/template";
import { walkerFrames } from "../../lib/walk/sprites.js";

const spriteStyle = (userId) =>
  trustHTML(`background-image: url(${walkerFrames(userId)[0]})`);

const WalkSprite = <template>
  <span
    aria-hidden="true"
    class="walk-sprite {{@class}}"
    style={{spriteStyle @userId}}
  ></span>
</template>;

export default WalkSprite;
