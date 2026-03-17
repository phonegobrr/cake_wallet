abstract class ActionListItem {
  ActionListItem({required this.listItemId});

  DateTime get date;

  /// Unique identifier for this list item. Flutter UI wraps in ValueKey() as needed.
  Object listItemId;
}