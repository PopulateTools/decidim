import Link from "@tiptap/extension-link";
import { Plugin } from "prosemirror-state";

import { getDictionary } from "src/decidim/refactor/moved/i18n";
import InputDialog from "src/decidim/editor/common/input_dialog";
import createBubbleMenu from "src/decidim/editor/extensions/link/bubble_menu";

export default Link.extend({
  addStorage() {
    return { bubbleMenu: null };
  },

  onCreate() {
    this.parent?.();

    this.storage.bubbleMenu = createBubbleMenu(this.editor);
  },

  onDestroy() {
    this.parent?.();

    this.storage.bubbleMenu.destroy();
    this.storage.bubbleMenu = null;
  },

  addOptions() {
    return {
      ...this.parent?.(),
      allowTargetControl: false,
      HTMLAttributes: {
        target: "_blank",
        class: null
      }
    }
  },

  addCommands() {
    const i18n = getDictionary("editor.extensions.link");
    const findNodeByAttribute = (doc, nodeType, attrName, attrValue) => {
      let foundNode = null;
      let foundPos = null;

      doc.descendants((node, pos) => {
        if (node.type.name === nodeType && node.attrs[attrName] === attrValue) {
          foundNode = node;
          foundPos = pos;
          return false; // stop searching
        }
      });

      return { node: foundNode, pos: foundPos };
    };

    return {
      ...this.parent?.(),

      toggleLinkBubble: () => ({ dispatch }) => {
        if (dispatch) {
          if (this.editor.isActive("link")) {
            this.storage.bubbleMenu.show();
            return true;
          }

          this.storage.bubbleMenu.hide();
          return false;
        }
        return this.editor.isActive("link");
      },

      linkDialog: () => async ({ dispatch, commands }) => {
        if (dispatch) {
          // Check if the selection is an image
          const isImage = this.editor.isActive("image");

          // If the cursor is within the link but the link is not selected, the
          // link would not be correctly updated. Also if only a part of the
          // link is selected, the link would be split to separate links, only
          // the current selection getting the updated link URL.
          if (!isImage) {
            commands.extendMarkRange("link");
          }

          this.storage.bubbleMenu.hide();

          const { allowTargetControl } = this.options;

          let { href, target } = this.editor.getAttributes("link");
          let src = null;
          let originalWidth = null;

          // If it's an image, get the src attribute and preserve the width
          if (isImage) {
            const imageAttrs = this.editor.getAttributes("image");
            src = imageAttrs.src;
            originalWidth = imageAttrs.width;
            // Check if the image is already wrapped in an imageLink
            const imageLinkAttrs = this.editor.getAttributes("imageLink");
            if (imageLinkAttrs.href) {
              href = imageLinkAttrs.href;
            }
          }

          const inputs = { href: { type: "text", label: i18n.hrefLabel } };
          if (allowTargetControl) {
            inputs.target = {
              type: "select",
              label: i18n.targetLabel,
              options: [
                { value: "", label: i18n["targets.default"] },
                { value: "_blank", label: i18n["targets.blank"] }
              ]
            }
          }

          const linkDialog = new InputDialog(this.editor, { inputs });
          const dialogState = await linkDialog.toggle({ href, target });
          href = linkDialog.getValue("href");
          target = linkDialog.getValue("target");
          if (!allowTargetControl) {
            target = "_blank";
          } else if (!target || target.length < 1) {
            target = null;
          }

          if (dialogState !== "save") {
            this.editor.chain().focus(null, { scrollIntoView: false }).toggleLinkBubble().run();
            return false;
          }

          if (!href || href.trim().length < 1) {
            if (isImage) {
              // For images, we don't unset anything if there's no href
              return this.editor.chain().focus(null, { scrollIntoView: false }).run();
            }
            return this.editor.chain().focus(null, { scrollIntoView: false }).unsetLink().run();
          }

          // If it's an image, use setImageLink command
          if (isImage) {
            // First apply the image link
            this.editor.chain()
              .focus(null, { scrollIntoView: false })
              .setImageLink({
                href,
                src,
                HTMLAttributes: {
                  target: target || "_blank"
                }
              })
              .run();

            // After setImageLink, find the image node by its src and update the width
            // Small delay to ensure the node is fully created after setImageLink
            setTimeout(() => {
              const { state, view } = this.editor;
              const { node: imageNode, pos: imagePos } = findNodeByAttribute(state.doc, "image", "src", src);

              if (imageNode && imagePos !== null) {
                const tr = state.tr.setNodeMarkup(imagePos, null, {
                  ...imageNode.attrs,
                  width: originalWidth
                });
                view.dispatch(tr);
              }
            }, 10);

            return true;
          }

          return this.editor.chain().focus(null, { scrollIntoView: false }).setLink({ href, target }).toggleLinkBubble().run();
        }

        return true;
      }
    }
  },

  addProseMirrorPlugins() {
    const editor = this.editor;

    return [
      ...(this.parent?.() || {}),
      new Plugin({
        props: {
          handleDoubleClick() {
            if (!editor.isActive("link")) {
              return false;
            }

            editor.chain().focus().linkDialog().run();
            return true;
          }
        }
      })
    ];
  }
});
