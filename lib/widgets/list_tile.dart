import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/locales.dart';
import 'package:login/widgets/show_time.dart';
import 'package:remixicon/remixicon.dart';
import 'package:intl/intl.dart';
import 'package:login/utils/alert.dart';
import 'package:login/utils/auth.dart';
import 'package:login/utils/sqlite.dart';

class MyListTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final double width;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  const MyListTile({
    super.key,
    required this.item,
    required this.width,
    required this.isExpanded,
    required this.onTap,
    required this.onRemove,
  });

  @override
  TileState createState() => TileState();
}

class TileState extends State<MyListTile> {
  bool isPressed = false;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    formatData();
  }

  @override
  void didUpdateWidget(covariant MyListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      formatData();
    }
  }

  void formatData() {
    if (widget.item['accounts'].length > 0) {
      var accounts = (widget.item['accounts'] as List<dynamic>).map((account) {
        var name = account['name'];
        String? domain = account['domain']?.toString();
        if (domain != null && domain.isNotEmpty) {
          name = '$name($domain)';
        }
        DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
          account['timestamp'] * 1000,
        );
        String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
        return {'id': account['id'], 'name': name, 'lastTime': formattedTime};
      }).toList();
      setState(() {
        items = accounts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: widget.onTap,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 6,
                color: TDTheme.of(context).grayColor1,
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    TDSwipeCell(
                      cell: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        padding: EdgeInsets.all(16),
                        color: isPressed ? Color(0xFFF8F8F8) : Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.isExpanded
                                          ? Remix.arrow_drop_up_line
                                          : Remix.arrow_drop_down_line,
                                      size: 24,
                                      color: widget.isExpanded
                                          ? TDTheme.of(context).brandColor7
                                          : TDTheme.of(context).fontGyColor1,
                                    ),
                                    Text(
                                      widget.item['email'],
                                      style: TextStyle(
                                        color: widget.isExpanded
                                            ? TDTheme.of(context).brandColor7
                                            : TDTheme.of(context).fontGyColor1,
                                        fontSize:
                                            TDTheme.of(
                                              context,
                                            ).fontBodyLarge?.size ??
                                            16,
                                        height:
                                            TDTheme.of(
                                              context,
                                            ).fontBodyLarge?.height ??
                                            24,
                                        fontWeight: widget.isExpanded
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ShowTotpTime(secretKey: widget.item['secret']),
                          ],
                        ),
                      ),
                      right: TDSwipeCellPanel(
                        extentRatio: 100 / widget.width,
                        children: [
                          TDSwipeCellAction(
                            flex: 100,
                            backgroundColor: TDTheme.of(context).errorColor6,
                            label: Lang.t('delete'),
                            onPressed: (context) {
                              widget.onRemove?.call();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        widget.isExpanded
            ? Column(
                children: [
                  TDDivider(),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
                    padding: EdgeInsetsGeometry.all(0),
                    child: TDTable(
                      empty: TDTableEmpty(text: Lang.t('noResults')),
                      columns: [
                        TDTableCol(
                          title: Lang.t('colName'),
                          colKey: 'name',
                          ellipsis: true,
                        ),
                        TDTableCol(
                          title: Lang.t('lastTime'),
                          colKey: 'lastTime',
                          align: TDTableColAlign.right,
                        ),
                      ],
                      data: items,
                      onCellLongPress: (index, data, col) async {
                        confirm(
                          data['name'],
                          Lang.t('delete'),
                          content: Lang.t('confirmDelete'),
                          onTap: () async {
                            var result = await authenticateWithBiometrics();
                            if (result['authenticated'] == false) {
                              return;
                            }
                            items.removeAt(index);
                            await deleteAccount(data['id']);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }
}
