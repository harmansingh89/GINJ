class SubmissionLockState {
  const SubmissionLockState({
    required this.isBlocked,
    required this.message,
    required this.buttonMessage,
  });

  final bool isBlocked;
  final String? message;
  final String? buttonMessage;

  static const none = SubmissionLockState(
    isBlocked: false,
    message: null,
    buttonMessage: null,
  );

  static const processing = SubmissionLockState(
    isBlocked: true,
    message:
        'Your submission is under process. Your selected prize will be dispatched soon.',
    buttonMessage:
        'Your submission is under process. Your selected prize will be dispatched soon.',
  );

  static const dispatched = SubmissionLockState(
    isBlocked: true,
    message:
        'A new Gurbani, Jiwani, or History can be selected only after your current prize has been successfully delivered. Please wait until the delivery is completed before making a new selection.',
    buttonMessage:
        'The selected prize has already been dispatched. Once it is delivered, you can select or change anything you\'d like.',
  );

  static const returned = SubmissionLockState(
    isBlocked: true,
    message:
        'Your prize was returned. We are looking into the issue and are working to resolve it. Please wait for further updates.',
    buttonMessage:
        'Your prize was returned. We are looking into the issue and are working to resolve it. Please wait for further updates.',
  );
}

SubmissionLockState deriveSubmissionLockState(
    Map<String, dynamic>? submission) {
  if (submission == null) {
    return SubmissionLockState.none;
  }

  final dispatch = submission['dispatch'] as Map<String, dynamic>?;
  final deliveryStatus = (dispatch?['deliveryStatus'] as String?)?.trim();
  final normalizedDelivery = deliveryStatus?.toLowerCase();

  if (normalizedDelivery == 'delivered') {
    return SubmissionLockState.none;
  }

  if (normalizedDelivery == 'returned') {
    return SubmissionLockState.returned;
  }

  if (normalizedDelivery == 'dispatched' ||
      normalizedDelivery == 'in transit' ||
      normalizedDelivery == 'intransit' ||
      normalizedDelivery == 'transit') {
    return SubmissionLockState.dispatched;
  }

  final status = (submission['status'] as String?)?.trim() ?? 'Pending';
  final whatsAppStatus =
      (submission['whatsAppTestStatus'] as String?)?.trim() ?? 'Pending';

  if (whatsAppStatus == 'Passed' ||
      status == 'Approved' ||
      status != 'Pending') {
    return SubmissionLockState.processing;
  }

  return SubmissionLockState.none;
}
