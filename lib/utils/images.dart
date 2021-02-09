import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fusecash/constants/addresses.dart';
import 'package:fusecash/models/community/business.dart';
import 'package:fusecash/models/community/community.dart';
import 'package:fusecash/models/transactions/transfer.dart';

class ImageUrl {
  static bool _isIpfsHash(String hash) => hash != null && hash.length == 46;
  static bool _isS3Hash(String hash) => hash != null && hash.length == 64;

  static String getLink(hash) {
    if (_isIpfsHash(hash)) {
      return getIPFSImageUrl(hash);
    } else if (_isS3Hash(hash)) {
      return getS3ImageUrl(hash);
    }
    return 'https://cdn3.iconfinder.com/data/icons/abstract-1/512/no_image-512.png';
  }

  static String getIPFSImageUrl(String image) {
    if (image == null) {
      return 'https://cdn3.iconfinder.com/data/icons/abstract-1/512/no_image-512.png';
    }
    return DotEnv().env['IPFS_BASE_URL'] + '/image/' + image;
  }

  static String getS3ImageUrl(String image) {
    if (image == null) {
      return 'https://cdn3.iconfinder.com/data/icons/abstract-1/512/no_image-512.png';
    }
    return '${DotEnv().env['FUSE_S3_BUCKET']}/$image';
  }

  static String getTokenUrl(tokenAddress) {
    return tokenAddress == Addresses.ZERO_ADDRESS
        ? 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png'
        : "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/$tokenAddress/logo.png";
  }

  static ImageProvider getContactImage(
    Transfer transfer,
    Contact contact, {
    List<Business> businesses = const [],
  }) {
    if (contact?.avatar != null && contact.avatar.isNotEmpty) {
      return new MemoryImage(contact.avatar);
    } else if (businesses.isNotEmpty) {
      String accountAddress =
          transfer.type == 'SEND' ? transfer.to : transfer.from;
      Business business = businesses.firstWhere(
          (business) => business.account == accountAddress,
          orElse: () => null);
      if (business != null) {
        return NetworkImage(business?.metadata?.getImageUri());
      }
    }
    return new AssetImage('assets/images/anom.png');
  }

  static ImageProvider getTransferImage(
    Transfer transfer,
    Contact contact,
    Community community, {
    bool isZeroAddress,
  }) {
    if (isZeroAddress != null && isZeroAddress) {
      return AssetImage(
        'assets/images/ethereume_icon.png',
      );
    }
    if (transfer.isJoinCommunity() &&
        ![null, ''].contains(community?.metadata?.image)) {
      return new NetworkImage(community?.metadata?.getImageUri());
    } else if (transfer.isGenerateWallet()) {
      return new AssetImage(
        'assets/images/generate_wallet.png',
      );
    } else if (transfer.isJoinBonus()) {
      return new AssetImage(
        'assets/images/join.png',
      );
    } else if (contact?.avatar != null && contact.avatar.isNotEmpty) {
      return new MemoryImage(contact.avatar);
    } else if (community != null &&
        community?.homeBridgeAddress != null &&
        transfer?.to != null &&
        transfer?.to?.toLowerCase() ==
            community?.homeBridgeAddress?.toLowerCase()) {
      return new AssetImage(
        'assets/images/ethereume_icon.png',
      );
    }

    String accountAddress =
        transfer.type == 'SEND' ? transfer.to : transfer.from;
    Business business = community?.businesses?.firstWhere(
        (business) => business.account == accountAddress,
        orElse: () => null);
    if (business != null) {
      return NetworkImage(business?.metadata?.getImageUri());
    }
    return new AssetImage('assets/images/anom.png');
  }
}