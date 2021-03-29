import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fusecash/redux/viewsmodels/token_tile.dart';
import 'package:fusecash/widgets/default_logo.dart';
import 'package:flutter/material.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/models/tokens/token.dart';
import 'package:number_display/number_display.dart';

class TokenTile extends StatelessWidget {
  TokenTile({
    Key key,
    this.token,
    this.showPending = true,
    this.showBalance = true,
    this.onTap,
    this.quate,
    this.symbolHeight = 45.0,
    this.symbolWidth = 45.0,
  }) : super(key: key);
  final Function() onTap;
  final double quate;
  final bool showPending;
  final bool showBalance;
  final double symbolWidth;
  final double symbolHeight;
  final Token token;
  @override
  Widget build(BuildContext context) {
    final display = createDisplay(
      length: 5,
      decimal: 2,
    );

    final String price = token.priceInfo != null
        ? display(num.parse(token?.priceInfo?.total))
        : '0';
    // final bool isFuseTxs = token.originNetwork != null;
    return StoreConnector<AppState, TokenTileViewModel>(
      distinct: true,
      converter: TokenTileViewModel.fromStore,
      builder: (_, viewModel) {
        final bool isCommunityToken = viewModel.communities.any((element) =>
            element?.homeTokenAddress?.toLowerCase() != null &&
            element?.homeTokenAddress?.toLowerCase() == token?.address &&
            ![false, null].contains(element.metadata.isDefaultImage));
        final Widget leading = Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: (token.imageUrl != null && token.imageUrl.isNotEmpty ||
                      viewModel.tokensImages
                          .containsKey(token?.address?.toLowerCase()))
                  ? CachedNetworkImage(
                      width: symbolWidth,
                      height: symbolHeight,
                      imageUrl: viewModel.tokensImages
                              .containsKey(token?.address?.toLowerCase())
                          ? viewModel
                              ?.tokensImages[token?.address?.toLowerCase()]
                          : token?.imageUrl,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => DefaultLogo(
                        symbol: token?.symbol,
                        width: symbolWidth,
                        height: symbolHeight,
                      ),
                    )
                  : DefaultLogo(
                      symbol: token?.symbol,
                      width: symbolWidth,
                      height: symbolHeight,
                    ),
            ),
            // showPending &&
            //         token.transactions.list
            //             .any((transfer) => transfer.isPending())
            //     ? Container(
            //         width: symbolWidth,
            //         height: symbolHeight,
            //         child: CircularProgressIndicator(
            //           backgroundColor: Theme.of(context)
            //               .colorScheme
            //               .onSurface,
            //           strokeWidth: 3,
            //           valueColor: AlwaysStoppedAnimation<Color>(
            //               Theme.of(context)
            //                   .colorScheme
            //                   .onSurface),
            //         ))
            //     : SizedBox.shrink(),
            isCommunityToken
                ? Text(
                    token.symbol,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  )
                : SizedBox.shrink()
          ],
        );

        final Widget title = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          verticalDirection: VerticalDirection.down,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: AutoSizeText(
                token.name,
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 15,
                ),
              ),
            )
            // SizedBox(
            //   width: 5,
            // ),
            // SvgPicture.asset(
            //   'assets/images/go_to_pro.svg',
            //   width: 10,
            //   height: 10,
            // )
          ],
        );
        final Widget subtitle = showBalance
            ? Stack(
                overflow: Overflow.visible,
                alignment: AlignmentDirectional.bottomEnd,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Europa',
                      ),
                      children: <TextSpan>[
                        token.priceInfo != null
                            ? TextSpan(
                                text: '\$' + price,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ))
                            : TextSpan(
                                text: token.getBalance() + ' ' + token.symbol,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                      ],
                    ),
                  ),
                  token.priceInfo != null
                      ? Positioned(
                          bottom: -20,
                          child: Padding(
                            child: Text(
                              token.getBalance() + ' ' + token.symbol,
                              style: TextStyle(
                                color: Color(0xFF8D8D8D),
                                fontSize: 10,
                              ),
                            ),
                            padding: EdgeInsets.only(top: 10),
                          ),
                        )
                      : SizedBox.shrink()
                ],
              )
            : SizedBox.shrink();

        return ListTile(
          leading: leading,
          onTap: onTap != null ? onTap : null,
          // : () {
          //     ExtendedNavigator.of(context)
          //         .pushTokenScreen(tokenAddress: token.address);
          //   },
          contentPadding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 15,
            right: 15,
          ),
          title: title,
          trailing: subtitle,
        );
      },
    );
  }
}