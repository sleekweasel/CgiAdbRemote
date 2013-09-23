package uk.org.baverstock.cgiadbremote.slave;

import com.android.chimpchat.ChimpChat;
import uk.org.baverstock.cgiadbremote.master.AndroidDebugBridgeWrapper;

/**
 * Presents ChimpChat in a testable way. Thanks Google.
 */

public interface ChimpChatWrapper {
    class Noop implements ChimpChatWrapper {
        @Override
        public ChimpChat getChimpChat() {
            return null;
        }
    }

    class Real implements ChimpChatWrapper {
        @Override
        public ChimpChat getChimpChat() {
            new AndroidDebugBridgeWrapper.Real().getBridge();
            return ChimpChatSingleton.getChimpChat();
        }
    }
    ChimpChat getChimpChat();
}
