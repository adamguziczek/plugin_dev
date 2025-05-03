/*
  ==============================================================================

    VolumeControlPlugin - A simple volume control plugin using JUCE
    Created by: Kodu

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>

//==============================================================================
/**
 * VolumeControlProcessor - Main processor class for the volume control plugin
 */
class VolumeControlProcessor : public juce::AudioProcessor
{
public:
    //==============================================================================
    VolumeControlProcessor();
    ~VolumeControlProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;
    using AudioProcessor::processBlock;

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
    // Expose the volume parameter for the editor to access
    juce::AudioParameterFloat* getVolumeParameter() { return volumeParameter; }

private:
    //==============================================================================
    // Volume parameter
    juce::AudioParameterFloat* volumeParameter;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (VolumeControlProcessor)
};