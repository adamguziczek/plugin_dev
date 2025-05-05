/*
  ==============================================================================

    Plugin Processor Implementation
    
    This file contains the implementation of the audio processor.
    Add your DSP code in the processBlock() method.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
YourPluginAudioProcessor::YourPluginAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
#endif
{
    // CUSTOMIZE: Initialize your parameters here
    // Example:
    // addParameter(volumeParameter = new juce::AudioParameterFloat(
    //     "volume",                  // Parameter ID
    //     "Volume",                  // Parameter name
    //     0.0f,                      // Minimum value
    //     1.0f,                      // Maximum value
    //     0.7f                       // Default value
    // ));
    
    // CUSTOMIZE: Initialize any other member variables or processing objects here
}

YourPluginAudioProcessor::~YourPluginAudioProcessor()
{
    // CUSTOMIZE: Add any cleanup code here if needed
}

//==============================================================================
const juce::String YourPluginAudioProcessor::getName() const
{
    // CUSTOMIZE: Update this to match your actual plugin name
    return "Your Plugin Name";
}

bool YourPluginAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool YourPluginAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool YourPluginAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double YourPluginAudioProcessor::getTailLengthSeconds() const
{
    // CUSTOMIZE: Update this if your plugin has a specific tail length
    // (e.g., for reverb or delay effects)
    return 0.0;
}

int YourPluginAudioProcessor::getNumPrograms()
{
    // CUSTOMIZE: Update this if your plugin uses programs (presets)
    return 1;   // Default: 1 program (preset)
}

int YourPluginAudioProcessor::getCurrentProgram()
{
    return 0;
}

void YourPluginAudioProcessor::setCurrentProgram (int index)
{
    // CUSTOMIZE: Add code to switch between presets
    juce::ignoreUnused(index);
}

const juce::String YourPluginAudioProcessor::getProgramName (int index)
{
    // CUSTOMIZE: Return the name of the specified preset
    juce::ignoreUnused(index);
    return {};
}

void YourPluginAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
    // CUSTOMIZE: Update the name of a preset
    juce::ignoreUnused(index, newName);
}

//==============================================================================
void YourPluginAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    // CUSTOMIZE: Prepare your processing objects for playback
    // Called when the audio device is starting or settings change
    
    // Example: Initialize DSP objects with the correct sample rate
    // dsp::ProcessSpec spec;
    // spec.sampleRate = sampleRate;
    // spec.maximumBlockSize = samplesPerBlock;
    // spec.numChannels = getTotalNumOutputChannels();
    // 
    // gainProcessor.prepare(spec);
    // gainProcessor.reset();
    
    // Reset any processing state if needed
    
    juce::ignoreUnused(sampleRate, samplesPerBlock);
}

void YourPluginAudioProcessor::releaseResources()
{
    // CUSTOMIZE: Free any resources when playback stops
    // Called when the audio device stops or when shutting down
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool YourPluginAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // CUSTOMIZE: Modify this if your plugin has specific channel requirements
    
    // Default: require matching input/output channel counts if not a synth
    
    // This checks if the input layout matches the output layout
   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    // This checks if the main output is stereo
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    return true;
  #endif
}
#endif

void YourPluginAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    // CUSTOMIZE: This is where you implement your audio processing!
    
    // Safety checks - don't modify these
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // Clear any output channels that don't have input channels
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    // CUSTOMIZE: Process the audio data here!
    // -----------------------------------------
    // Examples:
    
    // 1. Simple gain control:
    // float gainValue = *volumeParameter;
    // for (int channel = 0; channel < totalNumInputChannels; ++channel)
    // {
    //     auto* channelData = buffer.getWritePointer(channel);
    //     for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
    //     {
    //         channelData[sample] *= gainValue;
    //     }
    // }
    
    // 2. Using JUCE's DSP module:
    // juce::dsp::AudioBlock<float> block(buffer);
    // juce::dsp::ProcessContextReplacing<float> context(block);
    // gainProcessor.setGainLinear(*volumeParameter);
    // gainProcessor.process(context);
    
    // 3. Process MIDI data (if your plugin uses MIDI):
    // for (const auto metadata : midiMessages)
    // {
    //     const auto message = metadata.getMessage();
    //     const auto samplePosition = metadata.samplePosition;
    //     
    //     if (message.isNoteOn())
    //     {
    //         // Handle note on
    //     }
    //     else if (message.isNoteOff())
    //     {
    //         // Handle note off
    //     }
    // }
    
    // Don't forget to handle any relevant parameters from the AudioProcessorValueTreeState
    
    juce::ignoreUnused(midiMessages);
}

//==============================================================================
bool YourPluginAudioProcessor::hasEditor() const
{
    return true; // Change to false if you don't want an editor
}

juce::AudioProcessorEditor* YourPluginAudioProcessor::createEditor()
{
    // CUSTOMIZE: Uncomment one of these options:
    
    // For a custom editor (once you've created PluginEditor.h/cpp):
    // return new YourPluginAudioProcessorEditor (*this);
    
    // For a simple generic editor with parameter sliders:
    return new juce::GenericAudioProcessorEditor (*this);
}

//==============================================================================
void YourPluginAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // CUSTOMIZE: Store your parameters for session recall
    // This saves the plugin's state when the DAW's session is saved
    
    // Example using ValueTreeState:
    // auto state = parameters.copyState();
    // std::unique_ptr<juce::XmlElement> xml(state.createXml());
    // copyXmlToBinary(*xml, destData);
    
    // Example without ValueTreeState:
    // juce::MemoryOutputStream stream(destData, true);
    // stream.writeFloat(*volumeParameter);
    juce::ignoreUnused(destData);
}

void YourPluginAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // CUSTOMIZE: Restore your parameters from session data
    // This loads the plugin's state when the DAW's session is opened
    
    // Example using ValueTreeState:
    // std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));
    // if (xmlState.get() != nullptr && xmlState->hasTagName(parameters.state.getType()))
    //     parameters.replaceState(juce::ValueTree::fromXml(*xmlState));
    
    // Example without ValueTreeState:
    // juce::MemoryInputStream stream(data, static_cast<size_t> (sizeInBytes), false);
    // float savedVolume = stream.readFloat();
    // *volumeParameter = savedVolume;
    juce::ignoreUnused(data, sizeInBytes);
}

//==============================================================================
// This creates the plugin instance
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new YourPluginAudioProcessor();
}