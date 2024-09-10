import 'dart:io';
import 'package:auto_services_ai_notes/screen/final_route.dart';
import 'package:auto_services_ai_notes/screen/form_view.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/color_schema.dart';

final formViewModelProvider =
    StateNotifierProvider<FormViewModel, FormState>((ref) {
      // final formViewModel = FormViewModel();

      // ref.onDispose(() {
      //   formViewModel.dispose(); // Clean up when provider is disposed
      // });
      //
      return FormViewModel();
    });

class FormState {
  final String phoneNumber;
  final String retailName;
  final String metGM; // "Met" or "GM"
  final String metSD; // "Met" or "SD"
  final String interestLevel; // "Hot", "Warm", "Cold"
  final String visitSummary;
  final String nextAction;
  final File? businessCardImage;
  final String voiceUrl;

  FormState({
    this.voiceUrl = '',
    this.phoneNumber = '',
    this.retailName = '',
    this.metGM = '',
    this.metSD = '',
    this.interestLevel = '',
    this.visitSummary = '',
    this.nextAction = '',
    this.businessCardImage,
  });

  FormState copyWith({
    String? phoneNumber,
    String? retailName,
    String? metGM,
    String? metSD,
    String? interestLevel,
    String? visitSummary,
    String? nextAction,
    File? businessCardImage,
  }) {
    return FormState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      retailName: retailName ?? this.retailName,
      metGM: metGM ?? this.metGM,
      metSD: metSD ?? this.metSD,
      interestLevel: interestLevel ?? this.interestLevel,
      visitSummary: visitSummary ?? this.visitSummary,
      nextAction: nextAction ?? this.nextAction,
      businessCardImage: businessCardImage ?? this.businessCardImage,
    );
  }
}
class FormViewModel extends StateNotifier<FormState> {
  FormViewModel() : super(FormState());
  bool loading = false;

  final _picker = ImagePicker();

  // Any resources that need to be cleaned up should be handled here
  // @override
  // void dispose() {
  //   // Clean up resources, such as closing streams, canceling subscriptions, etc.
  //   print("FormViewModel disposed");
  //
  //   super.dispose();
  // }

  // Reset the form state to initial values
// Reset the form state to initial values
  void resetState() {
    state = state.copyWith(
      phoneNumber: '', // Reset to empty string or any default values
      retailName: '',
      metGM: '',
      metSD: '',
      interestLevel: '',
      visitSummary: '',
      nextAction: '',
      businessCardImage: null, // Reset image to null
    );
    // state = FormState(
    //   phoneNumber: '', // Reset to empty string or any default values
    //   retailName: '',
    //   metGM: '',
    //   metSD: '',
    //   interestLevel: '',
    //   visitSummary: '',
    //   nextAction: '',
    //   businessCardImage: null, // Reset image to null
    //   voiceUrl: "", // Reset voice URL to empty
    // );
  }
  void updateEmail(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  void updateRetailName(String value) {
    state = state.copyWith(retailName: value);
  }

  void updateMetGM(String value) {
    state = state.copyWith(metGM: value);
  }

  void updateMetSD(String value) {
    state = state.copyWith(metSD: value);
  }

  void updateInterestLevel(String value) {
    state = state.copyWith(interestLevel: value);
  }

  void updateVisitSummary(String value) {
    state = state.copyWith(visitSummary: value);
  }
  void updateNextAction(String value) {
    state = state.copyWith(nextAction: value);
  }
  //first thing
  void setLoading(bool value) {
    loading = value;
    state = state.copyWith(); // Trigger a rebuild by updating the state
  }
  Future<void> pickBusinessCardImage(BuildContext context,String voiceUrl) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      state = state.copyWith(businessCardImage: File(pickedFile.path));
      Navigator.push(context, MaterialPageRoute(builder: (context)=>FinalRoute(voiceUrl)));
    }
  }

 Future<void> submitForm(String voiceUrl,BuildContext context) async {
    // Start the loading state
    setLoading(true);

    try {
      // Get a reference to the Realtime Database
      final dbRef = FirebaseDatabase.instance.ref().child('formData').child(state.phoneNumber);

      // Generate a new key (ref ID) for this entry
      final newRef = dbRef.push();
      final refId = newRef.key; // Get the generated key

      // Prepare the Firebase Storage reference for the business card image
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('business_cards/${DateTime.now().toIso8601String()}');

      // Upload the business card image to Firebase Storage
      if (state.businessCardImage != null) {
        final uploadTask = storageRef.putFile(state.businessCardImage!);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Save the form data along with the ref ID to Realtime Database
        await newRef.set({
          'refId': refId, // Save the generated ref ID here
          'phoneNumber': state.phoneNumber,
          'retailName': state.retailName,
          'metGM': state.metGM,
          'metSD': state.metSD,
          'interestLevel': state.interestLevel,
          'visitSummary': state.visitSummary,
          'nextAction': state.nextAction,
          'businessCardUrl': downloadUrl,
          'voiceUrl': voiceUrl,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form Submitted Successfully'.toUpperCase(),style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w500
            ,color: kWhiteColor
        ),)),
      );
      // If successful, reset the state
      // resetState();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const FormView()));
    } catch (e) {
      // Handle any errors during the process
      print("Error during form submission: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during form submission: $e'.toUpperCase(),style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w500
            ,color: kWhiteColor
        ),)),
      );
      // You can also show an error message to the user or log it to a service like Firebase Crashlytics
    } finally {
      // Stop the loading state, regardless of success or failure
      setLoading(false);
    }
  }

}
