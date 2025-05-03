/*
  ==============================================================================

    VolumeControlPlugin - A simple volume control plugin using JUCE
    Created by: Kodu

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
VolumeControlProcessorEditor::VolumeControlProcessorEditor (VolumeControlProcessor& p)
    : AudioProcessorEditor (&p), processorRef (p)
{
    // Set up the volume slider
    volumeSlider.setSliderStyle (juce::Slider::LinearVertical);
    volumeSlider.setRange (0.0, 1.0, 0.01);
    volumeSlider.setTextBoxStyle (juce::Slider::TextBoxBelow, false, 90, 20);
    volumeSlider.setValue (*p.getVolumeParameter(), juce::dontSendNotification);
    volumeSlider.setDoubleClickReturnValue (true, 0.7); // Double-click resets to 70%
    volumeSlider.setTextValueSuffix (" Volume");
    volumeSlider.addListener (this);
    addAndMakeVisible (volumeSlider);
    
    // Set up the volume label
    volumeLabel.setText ("Volume", juce::dontSendNotification);
    volumeLabel.setFont (juce::Font (15.0f, juce::Font::bold));
    volumeLabel.setJustificationType (juce::Justification::centred);
    addAndMakeVisible (volumeLabel);
    
    // Set the plugin window size
    setSize (200, 300);
}

VolumeControlProcessorEditor::~VolumeControlProcessorEditor()
{
    volumeSlider.removeListener (this);
}

//==============================================================================
void VolumeControlProcessorEditor::paint (juce::Graphics& g)
{
    // Fill the background
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
    
    // Add a border around the plugin
    g.setColour (juce::Colours::white);
    g.drawRect (getLocalBounds(), 1);
    
    // Add a title
    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawFittedText ("Volume Control Plugin", getLocalBounds().removeFromTop(30), 
                      juce::Justification::centred, 1);
}

void VolumeControlProcessorEditor::resized()
{
    // Layout the components
    auto area = getLocalBounds().reduced (10);
    
    // Position the title area
    area.removeFromTop (20);
    
    // Position the volume label
    volumeLabel.setBounds (area.removeFromTop (20));
    
    // Position the volume slider (centered)
    volumeSlider.setBounds (area.reduced (area.getWidth() / 4, 10));
}

void VolumeControlProcessorEditor::sliderValueChanged (juce::Slider* slider)
{
    if (slider == &volumeSlider)
    {
        // Update the processor's volume parameter
        *processorRef.getVolumeParameter() = (float) volumeSlider.getValue();
    }
}