import 'dart:core';
import 'package:auto_route/auto_route.dart';
import 'package:fusecash/features/home/widgets/token_tile.dart';
import 'package:fusecash/features/swap/widgets/card.dart';
import 'package:fusecash/models/swap/swap.dart';
import 'package:fusecash/redux/actions/swap_actions.dart';
import 'package:fusecash/redux/viewsmodels/swap.dart';
import 'package:fusecash/services.dart';
import 'package:fusecash/utils/debouncer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusecash/generated/i18n.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/models/tokens/token.dart';
import 'package:fusecash/utils/format.dart';
import 'package:fusecash/widgets/my_scaffold.dart';
import 'package:fusecash/widgets/preloader.dart';
import 'package:fusecash/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fusecash/features/swap/router/swap_router.gr.dart';

class SwapScreen extends StatefulWidget {
  final Token primaryToken;
  SwapScreen({Key key, this.primaryToken}) : super(key: key);

  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final tokenOutDebouncer = Debouncer(milliseconds: 1000);
  final tokenInDebouncer = Debouncer(milliseconds: 1000);
  TextEditingController tokenInController = TextEditingController();
  TextEditingController tokenOutController = TextEditingController();
  SwapRequestBody swapRequestBody = SwapRequestBody();
  TradeInfo info;
  TradeInfo rateInfo;
  bool isFetchingPrice = false;
  Token tokenOut;
  Token tokenIn;
  List<Token> tokenList;
  bool isSwapped = false;

  @override
  void dispose() {
    tokenOutController.dispose();
    tokenInController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void onTokenOutChanged(Token token) {
    setState(() {
      tokenOut = token;
      swapRequestBody = swapRequestBody.copyWith(
        currencyIn: token.address,
      );
    });
    getTradeInfo(
      swapRequestBody.amountIn,
      (info) => setState(() {
        tokenOutController.text = info.outputAmount;
      }),
    );
  }

  void onTokenInChanged(Token token) {
    setState(() {
      tokenIn = token;
      swapRequestBody = swapRequestBody.copyWith(
        currencyOut: token.address,
      );
    });
    getTradeInfo(
      swapRequestBody.amountIn,
      (info) => setState(() {
        tokenInController.text = info.outputAmount;
      }),
    );
  }

  void getTradeInfo(
    String value,
    Function onSuccess,
  ) async {
    Function resetFields = () {
      setState(() {
        isFetchingPrice = false;
        tokenOutController.text = '';
        tokenInController.text = '';
      });
    };
    try {
      if (value.isNotEmpty) {
        setState(() {
          isFetchingPrice = true;
          swapRequestBody = swapRequestBody.copyWith(
            amountIn: value,
          );
        });
        TradeInfo tradeInfo = await swapService.trade(
          swapRequestBody.currencyIn,
          swapRequestBody.currencyOut,
          swapRequestBody.amountIn,
          swapRequestBody.recipient,
        );
        TradeInfo rate = await swapService.trade(
          swapRequestBody.currencyIn,
          swapRequestBody.currencyOut,
          '1',
          swapRequestBody.recipient,
        );
        setState(() {
          rateInfo = rate;
          info = tradeInfo;
          isFetchingPrice = false;
        });
        onSuccess(tradeInfo);
      } else {
        resetFields();
      }
    } catch (e) {
      resetFields();
    }
  }

  showBottomMenu(List<Token> tokens, onTap) {
    showModalBottomSheet(
      context: ExtendedNavigator.named('swapRouter').context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          color: Theme.of(context).canvasColor,
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          I18n.of(context).token,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Europa',
                            fontSize: 22,
                          ),
                          softWrap: true,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListView.separated(
                            shrinkWrap: true,
                            primary: false,
                            separatorBuilder: (_, int index) => Divider(
                              height: 0,
                            ),
                            itemCount: tokens?.length ?? 0,
                            itemBuilder: (context, index) => TokenTile(
                              token: tokens[index],
                              symbolWidth: 60,
                              symbolHeight: 60,
                              showPending: false,
                              onTap: () {
                                Navigator.of(context).pop();
                                onTap(tokens[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget swapWidgetIcon() {
    return InkWell(
      focusColor: Theme.of(context).canvasColor,
      highlightColor: Theme.of(context).canvasColor,
      onTap: () {
        if (this.mounted) {
          Token tokenPayWith = tokenOut.copyWith();
          Token tokenReceive = tokenIn.copyWith();
          String amountOut = tokenOutController.text;
          String amountIn = tokenInController.text;
          setState(() {
            isSwapped = !isSwapped;
            tokenOut = tokenReceive;
            tokenIn = tokenPayWith;
            tokenInController.text = amountOut;
            tokenOutController.text = amountIn;
            swapRequestBody = swapRequestBody.copyWith(
              currencyIn: tokenReceive.address,
              currencyOut: tokenPayWith.address,
            );
          });
        }
      },
      child: SvgPicture.asset(
        'assets/images/${isSwapped ? 'swap_icon2.svg' : 'swap_icon.svg'}',
        fit: BoxFit.fill,
        width: 55,
        height: 55,
      ),
    );
  }

  Widget maxButton() {
    return Container(
      child: InkWell(
        focusColor: Theme.of(context).canvasColor,
        highlightColor: Theme.of(context).canvasColor,
        onTap: () {
          String max = formatValue(
            tokenOut.amount,
            tokenOut.decimals,
            withPrecision: true,
          );
          setState(() {
            tokenOutController.text = max;
          });
          getTradeInfo(
            max,
            (info) => setState(() {
              tokenInController.text = info.outputAmount;
            }),
          );
        },
        child: Text(
          I18n.of(context).use_max,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      title: I18n.of(context).swap,
      body: StoreConnector<AppState, SwapViewModel>(
        distinct: true,
        converter: SwapViewModel.fromStore,
        onInit: (store) {
          store.dispatch(fetchSwapList());
        },
        onWillChange: (previousViewModel, newViewModel) {
          if (previousViewModel.tokens != newViewModel.tokens) {
            setState(() {
              tokenOutController.text = '';
              tokenInController.text = '';
              info = null;
              rateInfo = null;
              tokenOut = newViewModel.tokens[0];
              tokenIn = newViewModel.tokens[1];
              swapRequestBody = swapRequestBody.copyWith(
                recipient: newViewModel.walletAddress,
                currencyOut: newViewModel.tokens[1].address,
                currencyIn: newViewModel.tokens[0].address,
              );
            });
          }
        },
        builder: (_, viewModel) {
          if (viewModel.tokens.isEmpty) {
            return Preloader();
          } else {
            final bool hasFund =
                (tokenOut != null && tokenOut.amount > BigInt.zero);
            return InkWell(
              focusColor: Theme.of(context).canvasColor,
              highlightColor: Theme.of(context).canvasColor,
              onTap: () {
                WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: [
                            Column(
                              children: [
                                TradeCard(
                                  isSwapped: isSwapped,
                                  onTap: () {
                                    showBottomMenu(
                                      viewModel.tokens,
                                      onTokenOutChanged,
                                    );
                                  },
                                  onChanged: (value) {
                                    tokenOutDebouncer.run(
                                      () => getTradeInfo(
                                        value,
                                        (info) => setState(() {
                                          tokenInController.text =
                                              info.outputAmount;
                                        }),
                                      ),
                                    );
                                  },
                                  useMaxWidget: maxButton(),
                                  textEditingController: tokenOutController,
                                  token: tokenOut,
                                  title: I18n.of(context).pay_with,
                                ),
                                TradeCard(
                                  isSwapped: !isSwapped,
                                  onTap: () {
                                    showBottomMenu(
                                      viewModel.tokens,
                                      onTokenInChanged,
                                    );
                                  },
                                  onChanged: (value) {
                                    tokenInDebouncer.run(
                                      () => getTradeInfo(
                                        value,
                                        (info) => setState(() {
                                          tokenOutController.text =
                                              info.outputAmount;
                                        }),
                                      ),
                                    );
                                  },
                                  textEditingController: tokenInController,
                                  token: tokenIn,
                                  title: I18n.of(context).receive,
                                ),
                              ],
                            ),
                            swapWidgetIcon()
                          ],
                        ),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Center(
                        child: PrimaryButton(
                          disabled: isFetchingPrice || !hasFund,
                          preload: isFetchingPrice,
                          labelColor: hasFund ? null : Color(0xFF797979),
                          bgColor: hasFund
                              ? null
                              : Theme.of(context).colorScheme.secondary,
                          label: hasFund
                              ? I18n.of(context).review_swap
                              : I18n.of(context).insufficient_fund,
                          onPressed: () {
                            ExtendedNavigator.named('swapRouter')
                                .pushReviewSwapScreen(
                              rateInfo: rateInfo,
                              swapRequestBody: swapRequestBody,
                              tradeInfo: info,
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
