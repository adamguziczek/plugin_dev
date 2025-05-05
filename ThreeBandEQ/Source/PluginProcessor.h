/*
  ==============================================================================

    ThreeBandEQ Processor Header
    
    This file contains the basic framework code for a 3-band equalizer plugin.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>

//==============================================================================
/**
 * Main audio processor class for the 3-band equalizer plugin
 * 
 * This class handles:
 * - Audio processing for 3 frequency bands (low, mid, high)
 * - Parameter management for each band's gain and frequency
 * - Preset loading/saving
 */
class ThreeBandEQAudioProcessor : public juce::AudioProcessor
{
public:
    //==============================================================================
    ThreeBandEQAudioProcessor();
    ~ThreeBandEQAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    //==============================================================================
    // Audio parameters
    juce::AudioProcessorValueTreeState parameters;

private:
    //==============================================================================
    // DSP processing objects
    juce::dsp::ProcessorChain<
        juce::dsp::ProcessorDuplicator<juce::dsp::IIR::Filter<float>, juce::dsp::IIR::Coefficients<float>>, // Low band
        juce::dsp::ProcessorDuplicator<juce::dsp::IIR::Filter<float>, juce::dsp::IIR::Coefficients<float>>, // Mid band
        juce::dsp::ProcessorDuplicator<juce::dsp::IIR::Filter<float>, juce::dsp::IIR::Coefficients<float>>  // High band
    > processorChain;
    
    // Enumeration for processor chain indices
    enum ChainPositions {
        LowBand,
        MidBand,
        HighBand
    };
    
    // Processing context for audio blocks
    juce::dsp::AudioBlock<float> block;
    juce::dsp::ProcessContextReplacing<float> context;
    
    // Audio parameter creation helper
    juce::AudioProcessorValueTreeState::ParameterLayout createParameters();
    
    // Filter update methods
    void updateFilters();
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (ThreeBandEQAudioProcessor)
};