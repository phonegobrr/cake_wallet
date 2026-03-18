import 'package:cw_core/address_info.dart';
import 'package:cw_core/anonpay_invoice_info.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/contact.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/exchange_template.dart';
import 'package:cw_core/haven_seed_store.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/mweb_utxo.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/order.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/template.dart';
import 'package:cw_core/trade.dart';
import 'package:cw_core/transaction_description.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_type.dart';

/// Registers all shared Hive adapters from cw_core.
/// Idempotent — safe to call from multiple init paths.
///
/// Call this from:
///   - cake_wallet/lib/main.dart
///   - packages/cake_headless/lib/headless_init.dart
///   - Any other initialization entry point
void registerCoreHiveAdapters() {
  if (!CakeHive.isAdapterRegistered(Node.typeId)) {
    CakeHive.registerAdapter(NodeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(AddressInfo.typeId)) {
    CakeHive.registerAdapter(AddressInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(WALLET_TYPE_TYPE_ID)) {
    CakeHive.registerAdapter(WalletTypeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
    CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(MwebUtxo.typeId)) {
    CakeHive.registerAdapter(MwebUtxoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(PayjoinSession.typeId)) {
    CakeHive.registerAdapter(PayjoinSessionAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Erc20Token.typeId)) {
    CakeHive.registerAdapter(Erc20TokenAdapter());
  }
  if (!CakeHive.isAdapterRegistered(SPLToken.typeId)) {
    CakeHive.registerAdapter(SPLTokenAdapter());
  }
  if (!CakeHive.isAdapterRegistered(TronToken.typeId)) {
    CakeHive.registerAdapter(TronTokenAdapter());
  }
  // Extracted models (Section 2)
  if (!CakeHive.isAdapterRegistered(Contact.typeId)) {
    CakeHive.registerAdapter(ContactAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Trade.typeId)) {
    CakeHive.registerAdapter(TradeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Template.typeId)) {
    CakeHive.registerAdapter(TemplateAdapter());
  }
  if (!CakeHive.isAdapterRegistered(ExchangeTemplate.typeId)) {
    CakeHive.registerAdapter(ExchangeTemplateAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Order.typeId)) {
    CakeHive.registerAdapter(OrderAdapter());
  }
  if (!CakeHive.isAdapterRegistered(TransactionDescription.typeId)) {
    CakeHive.registerAdapter(TransactionDescriptionAdapter());
  }
  if (!CakeHive.isAdapterRegistered(AnonpayInvoiceInfo.typeId)) {
    CakeHive.registerAdapter(AnonpayInvoiceInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(HavenSeedStore.typeId)) {
    CakeHive.registerAdapter(HavenSeedStoreAdapter());
  }
}
