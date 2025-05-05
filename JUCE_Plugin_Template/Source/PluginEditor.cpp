/*
  ==============================================================================

    Plugin Editor Implementation
    
    This file contains the implementation of the plugin's custom UI.
    Uncomment and customize this code when you're ready for a custom UI.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
YourPluginAudioProcessorEditor::YourPluginAudioProcessorEditor (YourPluginAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    // CUSTOMIZE: Plugin editor setup
    
    // Set plugin editor size
    // The size of your plugin window in pixels
    setSize (400, 300);
    
    // Example of adding a slider:
    // ----------------------------
    // // Create and set up the volume slider
    // volumeSlider.setSliderStyle(juce::Slider::LinearVertical);
    // volumeSlider.setRange(0.0, 1.0);
    // volumeSlider.setValue(0.7);
    // volumeSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 90, 20);
    // volumeSlider.setPopupDisplayEnabled(true, false, this);
    // volumeSlider.setTextValueSuffix(" Volume");
    // 
    // // Add slider to the editor
    // addAndMakeVisible(&volumeSlider);
    // 
    // // Create and set up a label for the slider
    // volumeLabel.setText("Volume", juce::dontSendNotification);
    // volumeLabel.attachToComponent(&volumeSlider, false);
    // addAndMakeVisible(&volumeLabel);
    // 
    // // Add a listener to handle slider value changes
    // volumeSlider.addListener(this);
    // 
    // // Or connect to an AudioProcessorValueTreeState like this:
    // volumeSliderAttachment = new juce::AudioProcessorValueTreeState::SliderAttachment(
    //     audioProcessor.parameters, "volume", volumeSlider);
}

YourPluginAudioProcessorEditor::~YourPluginAudioProcessorEditor()
{
    // CUSTOMIZE: Clean up any resources here
    // Example:
    // volumeSlider.removeListener(this);
}

//==============================================================================
void YourPluginAudioProcessorEditor::paint (juce::Graphics& g)
{
    // CUSTOMIZE: Paint the plugin background
    
    // Fill the background with a color
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    // Example of drawing a border around the plugin
    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawText ("Your Plugin UI", getLocalBounds(),
                juce::Justification::centred, true);   
    
    // Example of drawing a border
    g.setColour (juce::Colours::grey);
    g.drawRect (getLocalBounds(), 1);   // draw an outline around the component
    
    // Other drawing examples:
    // -----------------------
    // Draw an image:
    // g.drawImageAt (backgroundImage, 0, 0);
    
    // Draw custom graphics:
    // g.setColour (juce::Colours::red);
    // g.fillEllipse (100.0f, 100.0f, 40.0f, 40.0f);
}

void YourPluginAudioProcessorEditor::resized()
{
    // CUSTOMIZE: Layout your UI components here
    // This is called when the editor is resized.
    // If you add any components to your editor, you should position them here.
    
    // Example of positioning UI components:
    // ------------------------------------
    // Rectangle layout:
    // auto area = getLocalBounds();
    // auto topSection = area.removeFromTop(100);
    // 
    // // Position a slider in the top section
    // volumeSlider.setBounds(topSection.reduced(10));
    
    // Grid layout:
    // juce::Grid grid;
    // using Track = juce::Grid::TrackInfo;
    // using Fr = juce::Grid::Fr;
    // 
    // grid.templateRows = { Track(Fr(1)), Track(Fr(3)), Track(Fr(1)) };
    // grid.templateColumns = { Track(Fr(1)), Track(Fr(1)) };
    // 
    // grid.items = {
    //     juce::GridItem(headerLabel).withArea(1, 1, 2, 3),
    //     juce::GridItem(volumeSlider).withArea(2, 1),
    //     juce::GridItem(panSlider).withArea(2, 2),
    //     juce::GridItem(footerLabel).withArea(3, 1, 4, 3)
    // };
    // 
    // grid.performLayout(getLocalBounds());
}

// Example of handling slider value changes:
// void YourPluginAudioProcessorEditor::sliderValueChanged(juce::Slider* slider)
// {
//     if (slider == &volumeSlider)
//     {
//         // Handle volume slider changes
//         float value = static_cast<float>(volumeSlider.getValue());
//         // Do something with the value, e.g.:
//         // audioProcessor.setVolume(value);
//     }
// }