import 'package:flutter/material.dart'
    show
        Border,
        BorderSide,
        BoxDecoration,
        BuildContext,
        Color,
        Colors,
        Directionality,
        EdgeInsets,
        FontWeight,
        MediaQuery,
        StatelessWidget,
        TextDirection,
        TextRange,
        TextSelection,
        ValueChanged,
        Widget,
        debugCheckHasMediaQuery,
        immutable;
import 'package:meta/meta.dart' show internal;
import '../../../../common/structs/horizontal_spacing.dart'
    show HorizontalSpacing;
import '../../../../common/structs/vertical_spacing.dart' show VerticalSpacing;
import '../../../../common/utils/font.dart' show getFontSizeAsDouble;
import '../../../../controller/quill_controller.dart' show QuillController;
import '../../../../delta/delta_diff.dart' show getDirectionOfNode;
import '../../../../document/attribute.dart' show Attribute;
import '../../../../document/nodes/block.dart' show Block;
import '../../../../document/nodes/line.dart' show Line;
import '../../../../toolbar/base_toolbar.dart' show hexToColor;
import '../../../embed/embed_editor_builder.dart' show EmbedsBuilder;
import '../../../provider.dart' show QuillEditorExt;
import '../../../raw_editor/builders/leading_block_builder.dart'
    show LeadingBlockNodeBuilder, LeadingConfigurations;
import '../../cursor.dart' show CursorCont;
import '../../default_leading_components/leading_components.dart'
    show
        bulletPointLeading,
        checkboxLeading,
        codeBlockLineNumberLeading,
        numberPointLeading;
import '../../default_styles.dart' show DefaultStyles, QuillStyles;
import '../../delegate.dart' show CustomRecognizerBuilder, CustomStyleBuilder;
import '../../link.dart' show LinkActionPicker;
import '../line/editable_text_line.dart' show EditableTextLine;
import '../line/text_line.dart' show TextLine;
import 'editable_text_block.dart' show EditableBlock;
import 'utils/text_block_utils.dart' show TextBlockUtils;

@internal
@immutable
class EditableTextBlock extends StatelessWidget {
  const EditableTextBlock({
    required this.block,
    required this.controller,
    required this.textDirection,
    required this.scrollBottomInset,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.textSelection,
    required this.color,
    required this.styles,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.contentPadding,
    required this.embedBuilder,
    required this.linkActionPicker,
    required this.cursorCont,
    required this.indentLevelCounts,
    required this.clearIndents,
    required this.onCheckboxTap,
    required this.readOnly,
    required this.customRecognizerBuilder,
    required this.composingRange,
    this.checkBoxReadOnly,
    this.onLaunchUrl,
    this.customStyleBuilder,
    this.customLinkPrefixes = const <String>[],
    this.customLeadingBlockBuilder,
    super.key,
  });

  final Block block;
  final QuillController controller;
  final TextDirection textDirection;
  final double scrollBottomInset;
  final HorizontalSpacing horizontalSpacing;
  final VerticalSpacing verticalSpacing;
  final TextSelection textSelection;
  final Color color;
  final DefaultStyles? styles;
  final LeadingBlockNodeBuilder? customLeadingBlockBuilder;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final EmbedsBuilder embedBuilder;
  final LinkActionPicker linkActionPicker;
  final ValueChanged<String>? onLaunchUrl;
  final CustomRecognizerBuilder? customRecognizerBuilder;
  final CustomStyleBuilder? customStyleBuilder;
  final CursorCont cursorCont;
  final Map<int, int> indentLevelCounts;
  final bool clearIndents;
  final Function(int, bool) onCheckboxTap;
  final bool readOnly;
  final bool? checkBoxReadOnly;
  final List<String> customLinkPrefixes;
  final TextRange composingRange;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final defaultStyles = QuillStyles.getStyles(context, false);
    return EditableBlock(
      block: block,
      textDirection: textDirection,
      horizontalSpacing: horizontalSpacing,
      verticalSpacing: verticalSpacing,
      scrollBottomInset: scrollBottomInset,
      decoration:
          _getDecorationForBlock(block, defaultStyles) ?? const BoxDecoration(),
      contentPadding: contentPadding,
      children: _buildChildren(
        context,
        indentLevelCounts,
        clearIndents,
      ),
    );
  }

  BoxDecoration? _getDecorationForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      // Verify if the direction is RTL and avoid passing the decoration
      // to the left when need to be on right side
      if (textDirection == TextDirection.rtl) {
        return defaultStyles!.quote!.decoration?.copyWith(
          border: Border(
            right: BorderSide(width: 4, color: Colors.grey.shade300),
          ),
        );
      }
      return defaultStyles!.quote!.decoration;
    }
    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }
    return null;
  }

  List<Widget> _buildChildren(BuildContext context,
      Map<int, int> indentLevelCounts, bool clearIndents) {
    final defaultStyles = QuillStyles.getStyles(context, false);
    final numberPointWidthBuilder =
        defaultStyles?.lists?.numberPointWidthBuilder ??
            TextBlockUtils.defaultNumberPointWidthBuilder;
    final indentWidthBuilder = defaultStyles?.lists?.indentWidthBuilder ??
        TextBlockUtils.defaultIndentWidthBuilder;

    final count = block.children.length;
    final children = <Widget>[];
    if (clearIndents) {
      indentLevelCounts.clear();
    }
    var index = 0;
    for (final line in Iterable.castFrom<dynamic, Line>(block.children)) {
      index++;
      final editableTextLine = EditableTextLine(
        line,
        _buildLeading(
          context: context,
          line: line,
          index: index,
          indentLevelCounts: indentLevelCounts,
          count: count,
        ),
        TextLine(
          line: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          customStyleBuilder: customStyleBuilder,
          styles: styles!,
          readOnly: readOnly,
          controller: controller,
          linkActionPicker: linkActionPicker,
          onLaunchUrl: onLaunchUrl,
          customLinkPrefixes: customLinkPrefixes,
          customRecognizerBuilder: customRecognizerBuilder,
          composingRange: composingRange,
        ),
        indentWidthBuilder(block, context, count, numberPointWidthBuilder),
        _getSpacingForLine(line, index, count, defaultStyles),
        textDirection,
        textSelection,
        color,
        enableInteractiveSelection,
        hasFocus,
        MediaQuery.devicePixelRatioOf(context),
        cursorCont,
        styles!.inlineCode!,
      );
      final nodeTextDirection = getDirectionOfNode(line, textDirection);
      children.add(
        Directionality(
          textDirection: nodeTextDirection,
          child: editableTextLine,
        ),
      );
    }
    return children.toList(growable: false);
  }

  Widget? _buildLeading({
    required BuildContext context,
    required Line line,
    required int index,
    required Map<int, int> indentLevelCounts,
    required int count,
  }) {
    final defaultStyles = QuillStyles.getStyles(context, false)!;
    final fontSize = defaultStyles.paragraph?.style.fontSize ?? 16;
    final attrs = line.style.attributes;
    final numberPointWidthBuilder =
        defaultStyles.lists?.numberPointWidthBuilder ??
            TextBlockUtils.defaultNumberPointWidthBuilder;

    // Of the color button
    final fontColor =
        line.toDelta().operations.first.attributes?[Attribute.color.key] != null
            ? hexToColor(
                line
                    .toDelta()
                    .operations
                    .first
                    .attributes?[Attribute.color.key],
              )
            : null;

    // Of the size button
    final size =
        line.toDelta().operations.first.attributes?[Attribute.size.key] != null
            ? getFontSizeAsDouble(
                line.toDelta().operations.first.attributes?[Attribute.size.key],
                defaultStyles: defaultStyles,
              )
            : null;

    // Of the alignment buttons
    // final textAlign = line.style.attributes[Attribute.align.key]?.value != null
    //     ? getTextAlign(line.style.attributes[Attribute.align.key]?.value)
    //     : null;
    final attribute =
        attrs[Attribute.list.key] ?? attrs[Attribute.codeBlock.key];
    final isUnordered = attribute == Attribute.ul;
    final isOrdered = attribute == Attribute.ol;
    final isCheck =
        attribute == Attribute.checked || attribute == Attribute.unchecked;
    final isCodeBlock = attrs.containsKey(Attribute.codeBlock.key);
    if (attribute == null) return null;
    final leadingConfigurations = LeadingConfigurations(
      attribute: attribute,
      attrs: attrs,
      indentLevelCounts: indentLevelCounts,
      index: isOrdered || isCodeBlock ? index : null,
      count: count,
      enabled: !isCheck ? null : !(checkBoxReadOnly ?? readOnly),
      style: () {
        if (isOrdered) {
          return defaultStyles.leading!.style.copyWith(
            fontSize: size,
            color: context.quillEditorElementOptions?.orderedList
                        .useTextColorForDot ==
                    true
                ? fontColor
                : null,
          );
        }
        if (isUnordered) {
          return defaultStyles.leading!.style.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: size,
            color: context.quillEditorElementOptions?.unorderedList
                        .useTextColorForDot ==
                    true
                ? fontColor
                : null,
          );
        }
        if (isCheck) {
          return null;
        }
        return defaultStyles.code!.style.copyWith(
          color: defaultStyles.code!.style.color!.withOpacity(0.4),
        );
      }(),
      width: () {
        if (isOrdered || isCodeBlock) {
          return numberPointWidthBuilder(fontSize, count);
        }
        if (isUnordered) {
          return numberPointWidthBuilder(fontSize, 1); // same as fontSize * 2
        }
        return null;
      }(),
      padding: () {
        if (isOrdered || isUnordered) {
          return fontSize / 2;
        }
        if (isCodeBlock) {
          return fontSize;
        }
        return null;
      }(),
      lineSize: isCheck ? fontSize : null,
      uiBuilder: isCheck ? defaultStyles.lists?.checkboxUIBuilder : null,
      value: attribute == Attribute.checked,
      onCheckboxTap: !isCheck
          ? (value) {}
          : (value) => onCheckboxTap(line.documentOffset, value),
    );
    if (customLeadingBlockBuilder != null) {
      final leadingBlockNodeBuilder = customLeadingBlockBuilder?.call(
        line,
        leadingConfigurations,
      );
      if (leadingBlockNodeBuilder != null) {
        return leadingBlockNodeBuilder;
      }
    }

    if (isOrdered) {
      return numberPointLeading(leadingConfigurations);
    }

    if (isUnordered) {
      return bulletPointLeading(leadingConfigurations);
    }

    if (isCheck) {
      return checkboxLeading(leadingConfigurations);
    }
    if (isCodeBlock &&
        context.requireQuillEditorElementOptions.codeBlock.enableLineNumbers) {
      return codeBlockLineNumberLeading(leadingConfigurations);
    }
    return null;
  }

  VerticalSpacing _getSpacingForLine(
    Line node,
    int index,
    int count,
    DefaultStyles? defaultStyles,
  ) {
    var top = 0.0, bottom = 0.0;

    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          top = defaultStyles!.h1!.verticalSpacing.top;
          bottom = defaultStyles.h1!.verticalSpacing.bottom;
          break;
        case 2:
          top = defaultStyles!.h2!.verticalSpacing.top;
          bottom = defaultStyles.h2!.verticalSpacing.bottom;
          break;
        case 3:
          top = defaultStyles!.h3!.verticalSpacing.top;
          bottom = defaultStyles.h3!.verticalSpacing.bottom;
          break;
        case 4:
          top = defaultStyles!.h4!.verticalSpacing.top;
          bottom = defaultStyles.h4!.verticalSpacing.bottom;
          break;
        case 5:
          top = defaultStyles!.h5!.verticalSpacing.top;
          bottom = defaultStyles.h5!.verticalSpacing.bottom;
          break;
        case 6:
          top = defaultStyles!.h6!.verticalSpacing.top;
          bottom = defaultStyles.h6!.verticalSpacing.bottom;
          break;
        default:
          throw ArgumentError('Invalid level $level');
      }
    } else {
      final VerticalSpacing lineSpacing;
      if (attrs.containsKey(Attribute.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(Attribute.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(Attribute.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(Attribute.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(Attribute.align.key)) {
        lineSpacing = defaultStyles!.align!.lineSpacing;
      } else {
        // use paragraph linespacing as a default
        lineSpacing = defaultStyles!.paragraph!.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top, bottom);
  }
}