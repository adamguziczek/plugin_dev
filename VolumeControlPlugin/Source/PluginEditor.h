/*
  ==============================================================================

    VolumeControlPlugin - A simple volume control plugin using JUCE
    Created by: Kodu

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
 * VolumeControlProcessorEditor - Custom editor for the volume control plugin
 */
class VolumeControlProcessorEditor  : public juce::AudioProcessorEditor,
                                      private juce::Slider::Listener
{
public:
    VolumeControlProcessorEditor (VolumeControlProcessor&);
    ~VolumeControlProcessorEditor() override;

    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;

private:
    // This reference is provided as a quick way for your editor to
    // access the processor object that created it.
    VolumeControlProcessor& processorRef;
    
    // Called when the slider value changes
    void sliderValueChanged (juce::Slider* slider) override;
    
    // UI Components
    juce::Slider volumeSlider;
    juce::Label volumeLabel;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (VolumeControlProcessorEditor)
};