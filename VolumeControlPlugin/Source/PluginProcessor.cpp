/*
  ==============================================================================

    VolumeControlPlugin - A simple volume control plugin using JUCE
    Created by: Kodu

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
VolumeControlProcessor::VolumeControlProcessor()
    : AudioProcessor (BusesProperties()
                      .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     )
{
    // Add volume parameter (0.0 to 1.0, default 0.7)
    addParameter (volumeParameter = new juce::AudioParameterFloat (
        "volume",                   // parameter ID
        "Volume",                   // parameter name
        0.0f,                       // minimum value
        1.0f,                       // maximum value
        0.7f                        // default value
    ));
}

VolumeControlProcessor::~VolumeControlProcessor()
{
}

//==============================================================================
const juce::String VolumeControlProcessor::getName() const
{
    return JucePlugin_Name;
}

bool VolumeControlProcessor::acceptsMidi() const
{
    return false;
}

bool VolumeControlProcessor::producesMidi() const
{
    return false;
}

bool VolumeControlProcessor::isMidiEffect() const
{
    return false;
}

double VolumeControlProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int VolumeControlProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int VolumeControlProcessor::getCurrentProgram()
{
    return 0;
}

void VolumeControlProcessor::setCurrentProgram (int index)
{
    juce::ignoreUnused (index);
}

const juce::String VolumeControlProcessor::getProgramName (int index)
{
    juce::ignoreUnused (index);
    return {};
}

void VolumeControlProcessor::changeProgramName (int index, const juce::String& newName)
{
    juce::ignoreUnused (index, newName);
}

//==============================================================================
void VolumeControlProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    // Use this method as the place to do any pre-playback
    // initialisation that you need..
    juce::ignoreUnused (sampleRate, samplesPerBlock);
}

void VolumeControlProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

bool VolumeControlProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;

    return true;
}

void VolumeControlProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ignoreUnused (midiMessages);

    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // In case we have more outputs than inputs, clear any output
    // channels that didn't contain input data
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    // Apply volume to the buffer
    buffer.applyGain (*volumeParameter);
}

//==============================================================================
bool VolumeControlProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* VolumeControlProcessor::createEditor()
{
    return new VolumeControlProcessorEditor (*this);
}

//==============================================================================
void VolumeControlProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
    
    // Create an XML element to store our state
    auto state = std::make_unique<juce::XmlElement>("VolumeControlState");
    
    // Store the volume parameter
    state->setAttribute("volume", (double) *volumeParameter);
    
    // Convert to binary and store in destData
    copyXmlToBinary(*state, destData);
}

void VolumeControlProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
    
    // Create an XML element from the binary data
    std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));
    
    // Check if the XML is valid and has the correct tag name
    if (xmlState.get() != nullptr && xmlState->hasTagName("VolumeControlState"))
    {
        // Restore the volume parameter
        if (xmlState->hasAttribute("volume"))
            *volumeParameter = (float) xmlState->getDoubleAttribute("volume", 0.7);
    }
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new VolumeControlProcessor();
}