/*
  ==============================================================================

    Plugin Processor Header
    
    This file contains the basic framework code for a JUCE plugin processor.
    Use this template as a starting point for your audio plugin.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>

//==============================================================================
/**
 * Main audio processor class for your plugin
 * 
 * This class handles:
 * - Audio processing
 * - Parameter management
 * - Preset loading/saving
 * - Creating the editor UI
 */
class YourPluginAudioProcessor  : public juce::AudioProcessor
{
public:
    //==============================================================================
    /* Constructor and Destructor */
    YourPluginAudioProcessor();
    ~YourPluginAudioProcessor() override;

    //==============================================================================
    /* Before playback begins */
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    /* After playback finishes */
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    /* Verify channel configuration */
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    //==============================================================================
    /* The core audio processing function - implement your DSP here */
    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    /* Creates editor UI */
    juce::AudioProcessorEditor* createEditor() override;
    /* Can this processor have an UI? */
    bool hasEditor() const override;

    //==============================================================================
    /* Plugin information */
    const juce::String getName() const override;

    /* MIDI capabilities */
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    
    /* Tail length - how long processing continues after input ends */
    double getTailLengthSeconds() const override;

    //==============================================================================
    /* Program management (usually for preset handling) */
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    /* State saving/loading - for storing settings between sessions */
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    //==============================================================================
    /* CUSTOMIZE: Add your own parameters, member variables, and methods here */

    /* Example: Create an AudioParameterFloat for a volume control */
    // juce::AudioParameterFloat* volumeParameter;

private:
    //==============================================================================
    /* CUSTOMIZE: Add your private member variables and methods here */

    /* For example, you might declare DSP processing objects here, such as: */
    // juce::dsp::Gain<float> gainProcessor;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (YourPluginAudioProcessor)
};