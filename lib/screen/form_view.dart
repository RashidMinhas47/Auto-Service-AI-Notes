import 'package:auto_services_ai_notes/utils/color_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/tau.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/common_button.dart';
import '../components/common_text_field.dart';
import '../services/audio_services.dart';
import '../utils/const_widgets.dart';
import '../view_model/form_view_model.dart';

class FormView extends ConsumerStatefulWidget {
  const FormView({super.key});

  @override
  ConsumerState<FormView> createState() => _FormViewState();
}

class _FormViewState extends ConsumerState<FormView>  with SingleTickerProviderStateMixin {
 final AudioRecorder _audioRecorder = AudioRecorder();
  String? _downloadVoiceUrl;
 late AnimationController _controller;
 late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _audioRecorder.initializeRecorder();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Pulse effect repeats

    // Define animation to go from 1x to 1.2x scale
    _animation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.disposeRecorder();
    _controller.dispose(); // Dispose the animation controller
    super.dispose();

  }

  void _onRecordButtonPressed() async {

    if (_audioRecorder.isRecording) {
      // Stop recording
      await _audioRecorder.stopRecording();
      String? downloadUrl = await _audioRecorder.uploadAudioFile();
      setState(() {
        _downloadVoiceUrl = downloadUrl;
      });
    } else {
      // Start recording
      await _audioRecorder.startRecording();
    }

    setState(() {});  // To refresh button text
  }

  @override
  Widget build(BuildContext context) {
    final Size size =MediaQuery.of(context).size;
    final formState = ref.watch(formViewModelProvider);
    final formViewModel = ref.read(formViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: kBGDarkColor,
      appBar: AppBar(
        backgroundColor: kBGDarkColor,
        centerTitle: true,
        title: const Text('Auto Service AI Notes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonTextField(
              hintText: "Phone Number",

              label: "Phone Number",
              keyboardType: TextInputType.phone,
              onChanged: (value)=> formViewModel.updateEmail(value),),

            CommonTextField(
              hintText: "Retail Name",
              label: "Retail Name",
              onChanged:(value)=> formViewModel.updateRetailName(value),
            ),

            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                 Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text('Met GM',style: GoogleFonts.quicksand(fontSize: 20,fontWeight: FontWeight.w600),),
                  ),
                const Text('YES'),

                  Radio<String>(
                    value: 'YES',
                    groupValue: formState.metGM,
                    toggleable: true,
                    onChanged: (value) => formViewModel.updateMetGM(value!),
                  ),
                  const Text('NO'),
                  Radio<String>(
                    value: 'NO',
                    groupValue: formState.metGM,
                    onChanged: (value) => formViewModel.updateMetGM(value!),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text('Met SD',style: GoogleFonts.quicksand(fontWeight: FontWeight.w600,fontSize: 20),),
                  ),
                const  Text('YES'),

                  Radio<String>(
                    value: 'YES',
                    groupValue: formState.metSD,
                    // toggleable: true,
                    onChanged: (value) => formViewModel.updateMetSD(value!),
                  ),
                 const Text('NO'),
                  Radio<String>(
                    value: 'NO',
                    groupValue: formState.metSD,
                    onChanged: (value) => formViewModel.updateMetSD(value!),
                  ),

                ],
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("Interest",style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w600
                  ),),
                ),
                Container(
                  padding:const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: kBlackColor,borderRadius: BorderRadius.circular(12),border: Border.all(color: kWhiteColor)),
                  child: DropdownButton<String>(
                    underline: SizedBox.shrink(),
                    value: formState.interestLevel.isNotEmpty
                        ? formState.interestLevel
                        : null,
                    hint: const Text('Interested'),
                    items: kItems,
                    onChanged: (value) => formViewModel.updateInterestLevel(value!),
                  ),
                ),
              ],
            ),
            CommonTextField(
              hintText: "Visit Summ.",

              label: "Visit Summ.",
              onChanged: (value)=>formViewModel.updateVisitSummary(value),
              maxLines: 4,
            ),
            CommonTextField(
              hintText: "Next Action",

              label: "Next Action",
              onChanged: (value)=>formViewModel.updateNextAction(value),
            ),


           const SizedBox(height: 16.0),
            voiceRecordButton(size),

            CommonButton(onPressed: () async {
              await formViewModel.pickBusinessCardImage(context,_downloadVoiceUrl!);
            }
              ,label: 'Click to Take Photo of Bus Card',),


            // if (formState.businessCardImage != null)
            //   Image.file(formState.businessCardImage!, height: 200),
            // SizedBox(height: 16.0),
            // CommonButton(onPressed: () async {
            //
            //   await formViewModel.submitForm(_downloadVoiceUrl);
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(content: Text('Form Submitted!'.toUpperCase(),style: GoogleFonts.quicksand(
            //         fontWeight: FontWeight.w500
            //         ,color: kWhiteColor
            //     ),)),
            //   );
            // }, label: "Submit")
          ],
        ),
      ),
    );
  }

  Padding voiceRecordButton(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),

      child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _audioRecorder.isRecording ? _animation.value : 1.0,
                  child: ElevatedButton(
                    onPressed: _onRecordButtonPressed,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_audioRecorder.isRecording? Icons.record_voice_over: Icons.stop),
                        const SizedBox(width:10),
                        Text(
                          _audioRecorder.isRecording ? 'Stop Recording'.toUpperCase() : 'Start Recording'.toUpperCase(),
                        ),
                      ],
                    ),

                  ),
                );
              },
            ),
    );
  }
}

