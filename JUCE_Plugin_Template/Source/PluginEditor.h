/*
  ==============================================================================

    Plugin Editor Header
    
    This file contains the class definition for the plugin's custom UI.
    Uncomment and customize the editor code when you're ready for a custom UI.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
 * Custom UI component for the plugin
 * 
 * This class defines how your plugin looks and handles user interaction.
 * By default, this is commented out in PluginProcessor.cpp in favor of
 * using GenericAudioProcessorEditor, but you can uncomment it when
 * you're ready to create a custom UI.
 */
class YourPluginAudioProcessorEditor  : public juce::AudioProcessorEditor
{
public:
    /* Constructor and Destructor */
    YourPluginAudioProcessorEditor (YourPluginAudioProcessor&);
    ~YourPluginAudioProcessorEditor() override;

    //==============================================================================
    /* JUCE UI callbacks */
    
    /* Called when the editor needs to be redrawn */
    void paint (juce::Graphics&) override;
    
    /* Called when the editor is resized */
    void resized() override;

private:
    // CUSTOMIZE: Add your UI components here
    // For example:
    // juce::Slider volumeSlider;
    // juce::Label volumeLabel;
    
    // This reference is provided as a quick way to access the processor
    YourPluginAudioProcessor& audioProcessor;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (YourPluginAudioProcessorEditor)
};