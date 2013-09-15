//package uk.org.baverstock.cgiadbremote;
//
//import org.jmock.integration.junit4.JUnitRuleMockery;
//import org.jmock.lib.concurrent.Synchroniser;
//import org.jmock.lib.legacy.ClassImposteriser;
//
///**
// * Mock with extra magic stuff, use ThreadSafeJUnitRuleMockery.WithImposteriser,
// * or split the classes out and rename the inner one to something sensible.
// */
//
//public class ThreadSafeJUnitRuleMockery extends JUnitRuleMockery
//{
//    private ThreadSafeJUnitRuleMockery()
//    {
//        setThreadingPolicy(new Synchroniser());
//    }
//
//    static public class WithImposteriser extends ThreadSafeJUnitRuleMockery
//    {
//        public WithImposteriser()
//        {
//            super();
//            setImposteriser(ClassImposteriser.INSTANCE);
//        }
//    }
//
//    static public class WithoutImposteriser extends ThreadSafeJUnitRuleMockery
//    {
//    }
//}
